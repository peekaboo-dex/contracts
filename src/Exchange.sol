// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.13;

import "./IExchange.sol";
import "./RSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Exchange is IExchange, RSA, IERC721Receiver {

    // Current auction Id
    uint256 public currentAuctionId;

    // Mapping of all auctions
    mapping (uint256 => Auction) public auctions;

    // Mapping of all bids, by aucition id
    mapping (uint256 => mapping (address => SealedBid)) public sealedBids;

    // Mapping of unsealed bids, by auction id
    mapping (uint256 => mapping (address => UnsealedBid)) public unsealedBids;

    // Mapping of whether an account is settled for a given auction
    mapping (uint256 => mapping (address => bool)) public settled;

    // Amount of time from when the puzzle is solved until the auction is finalized.
    // During this time any bids can be revealed, but the top bid will ve known to all.
    // So only the top bid need be submitted
    uint256 immutable public finalityDelay;

    constructor(uint256 _finalityDelay) {
        finalityDelay = _finalityDelay;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // Creates an auction for an NFT.
    function createAuction(address tokenAddress, uint256 tokenId, uint256 publicKey, bytes calldata puzzle) external returns (uint256) {
        // Transfer token into exchange
        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        // Create auction
        uint256 auctionId = (currentAuctionId += 1);
        auctions[currentAuctionId] = Auction({
            auctionId: auctionId,
            auctioneer: msg.sender,
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            publicKey: publicKey,
            puzzle: Puzzle({
                input: puzzle,
                p: uint256(0),
                q: uint256(0),
                d: uint256(0)
            }),
            puzzleSolvedTimestamp: 0,
            currentHighestBidder: address(0),
            state: AuctionState.OPEN
        });
        emit AuctionCreated(
            auctionId,
            msg.sender,
            tokenAddress,
            tokenId,
            publicKey,
            puzzle
        );
        return auctionId;
    }

    // Solves the auction's puzzle. The solution is the secret key (p,q,d).
    // Once this is called anyone can decrypt the bids using the emitted event.
    function closeAuction(uint256 auctionId, uint256 p, uint256 q, uint256 d) external {
        // TODO - sanity checks

        // Store puzzle solution
        auctions[auctionId].puzzle.p = p;
        auctions[auctionId].puzzle.q = q;
        auctions[auctionId].puzzle.d = d;

        // Bids can now be revealed, so the auction is closed.
        auctions[auctionId].state = AuctionState.CLOSED;
        auctions[auctionId].puzzleSolvedTimestamp = block.timestamp;

        emit AuctionClosed(
            auctionId,
            p,
            q,
            d
        );
    }

    // Bidder commits to their bid for a given auction.
    // The bid is encrypted with the auction's public key.
    // msg.value = bid + obfuscation
    function commitBid(uint256 auctionId, uint256 sealedBid) external payable {
        // Sanity checks
        require(auctions[auctionId].state == AuctionState.OPEN, "Auction is not open");
        require(sealedBid != 0, "Sealed bid must be non-zero");
        require(msg.value != 0, "Must send ETH");
        // TODO - require that user has not already submitted

        // Commit bid
        sealedBids[auctionId][msg.sender] = SealedBid({
            value: sealedBid,
            ethSent: msg.value
        });
        emit BidCommitted(
            auctionId,
            msg.sender,
            sealedBid,
            msg.value
        );
    }

    // Reveal bid for input bidder. Sealed bids can be revealed once the puzzle has
    // been solved. Since once the puzzle is revealed 
    function revealBid(uint256 auctionId, address bidder) external returns (uint256) {
        // Sanity checks
        require(auctions[auctionId].state == AuctionState.CLOSED, "Bids can only be revealed when the auction is in CLOSED state");

        // Get puzzle for auction and assert that it is solved.
        Puzzle memory puzzle = auctions[auctionId].puzzle;
        require(_isPuzzleSolved(puzzle), "Cannot reveal sealed bid. Puzzle not solved.");

        // Fetch the sealed bid.
        SealedBid memory sealedBid = sealedBids[auctionId][bidder];
        require(sealedBid.value != 0 && sealedBid.ethSent != 0, "No sealed bid exists for user.");

        // Decrypt the sealed bid
        uint256 bid = decrypt(puzzle.p, puzzle.q, puzzle.d, sealedBid.value);
        bool isValidBid = sealedBid.ethSent >= bid;
        uint256 obfuscation = isValidBid ? sealedBid.ethSent - bid : 0;
        unsealedBids[auctionId][bidder] = UnsealedBid({
            bid: bid,
            obfuscation: obfuscation
        });

        // Check if this is the current highest bid
        bool isCurrentHighestBid = false;
        if (isValidBid) {
            // Fetcn current highest bidder
            address currentHighestBidder = auctions[auctionId].currentHighestBidder;
            if (currentHighestBidder == address(0)) {
                isCurrentHighestBid = true;
            } else if (bid > unsealedBids[auctionId][currentHighestBidder].bid) {
                // Note that if there's a tie then it's whoever gets there first.
                isCurrentHighestBid = true;
            }

            // Update auction if we are now the current highest bidder
            if (isCurrentHighestBid) {
                auctions[auctionId].currentHighestBidder = bidder;
            }
        }

        emit BidRevealed(
            auctionId, 
            bidder,
            bid,
            obfuscation,
            isCurrentHighestBid,
            isValidBid
        );

        return bid;
    }

    function finalizeAuction(uint256 auctionId) external {
        // Sanity check that we can finalize
        require(block.timestamp > auctions[auctionId].puzzleSolvedTimestamp + finalityDelay, "Auction cannot be finalized yet.");
        require(auctions[auctionId].state == AuctionState.CLOSED, "Auction is not yet closed. Cannot finalize.");

        // Set auction state to finalized - write state here to avoid re-entrancy problems.
        auctions[auctionId].state = AuctionState.FINALIZED;

        // Settle the auction. Two cases - either there is a winner or no winner.
        address auctioneer = auctions[auctionId].auctioneer;
        address winner = auctions[auctionId].currentHighestBidder;
        uint256 winningBid = unsealedBids[auctionId][auctioneer].bid;
        uint256 obfuscation = unsealedBids[auctionId][auctioneer].obfuscation;
        if (winner == address(0)) {
            // Refund the NFT to the auctioneer
            IERC721(auctions[auctionId].tokenAddress).safeTransferFrom(
                address(this),
                auctioneer,
                auctions[auctionId].tokenId
            );
            // Nobody bid / was revealed during the finality delay.
            auctions[auctionId].state = AuctionState.FINALIZED;
        } else {
            // Transfer the NFT to the bidder
            IERC721(auctions[auctionId].tokenAddress).safeTransferFrom(
                address(this),
                winner,
                auctions[auctionId].tokenId
            );

            // Settle for winner. This means that no further refund is required.
            settled[auctionId][winner] = true;
        

            // Transfer obfuscation amount back to winner
            // We don't check the success because that would allow the bidder to grief the auction.
            // No re-entrancy guard because state has already been updated.
            winner.call{value: obfuscation}("");
            
            // Transfer winning bid to auctioneer
            // We don't check the success because that would allow the auctioneer to grief the auction. 
            // No re-entrancy guard because state has already been updated.
            auctioneer.call{value: winningBid}("");

        }

        emit AuctionFinalized(
            auctionId,
            winner,
            winningBid
        );
    }

    // Losing bidder calls to reclaim all ETH sent
    function claimRefund(uint256 auctionId) external {
        require(auctions[auctionId].state == AuctionState.FINALIZED, "Auction ,ust be finalized before claiming refund.");
        require(!settled[auctionId][msg.sender], "This account has already settled");
        uint256 refundAmount = sealedBids[auctionId][msg.sender].ethSent;
        settled[auctionId][msg.sender] = true;
        (bool ok,) = msg.sender.call{value: refundAmount}("");
        require(ok, "Failed to claim refund");
    }

    function _isPuzzleSolved(Puzzle memory puzzle) internal pure returns (bool) {
        return puzzle.p != 0 && puzzle.q != 0 && puzzle.d != 0;
    }
}