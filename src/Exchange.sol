// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IExchange.sol";
import "./RSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Exchange is IExchange {

    // Current auction Id
    uint256 public currentAuctionId;

    // Mapping of all auctions
    mapping (uint256 => Auction) public auctions;

    // Mapping of all bids, by aucition id
    mapping (uint256 => mapping (address => SealedBid)) sealedBids;

    // Mapping of unsealed bids, by auction id
    mapping (uint256 => mapping (address => SealedBid)) unsealedBids;

    // 




    // Creates an auction for an NFT.
    function createAuction(address tokenAddress, uint256 tokenId, bytes calldata publicKey, bytes calldata puzzle) external returns (uint256) {
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
            currentHighestBidder: address(0),
            winner: address(0),
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
    function solveAuctionPuzzle(uint256 auctionId, uint256 p, uint256 q, uint256 d) external {
        // Verify inputs
        
        // Bids can now be revealed, so the auction is closed.
        auctions[auctionId].state = AuctionState.CLOSED;
    }

    // Bidder commits to their bid for a given auction.
    // The bid is encrypted with the auction's public key.
    // msg.value = bid + obfuscation
    function commitBid(uint256 auctionId, uint256 sealedBid) external payable {
        // Sanity checks
        require(auctions[auctionId].state == AuctionState.OPEN, "Auction is not open");
        require(sealedBid != 0, "Sealed bid must be non-zero");
        require(msg.value != 0, "Must send ETH");

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
    function revealBid(uint256 auctionId, address bidder) external {
        // Sanity checks
        require(auctions[auctionId].state == AuctionState.CLOSED, "Bids can only be revealed when the auction is in CLOSED state");

        // Get puzzle for auction and assert that it is solved.
        Puzzle memory puzzle = auctions[auctionId].puzzle;
        require(_isPuzzleSolved(puzzle), "Cannot reveal sealed bid. Puzzle not solved.");

        // Fetch the sealed bid.
        SealedBid memory sealedBid = sealedBids[auctionId][bidder];
        require(sealedBid. != 0, "No sealed bid exists for user.");

        // Decrypt the sealed bid
        uint256 bid = RSA.decrypt(puzzle.p, puzzle.q, puzzle.d, sealedBid.value);
        unsealedBids[auctionId][bidder] = bid;

        // Validate bid and compute obfuscation
        bool isValidBid = sealedBid.ethSent >= bid;
        uint256 obfuscation = isValidBid ? sealedBid.ethSent - bid : 0;

        // Check if this is the current highest bid
        bool isCurrentHighestBid = false;
        if (isValidBid) {
            // Fetcn current highest bidder
            uint256 currentHighestBidder = auctions[auctionId].currentHighestBidder;
            if (currentHighestBidder == address(0)) {
                isCurrentHighestBid = true;
            } else if (bid > unsealedBids[auctionId][currentHighestBidder]) {
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
    }

    function finalizeAuction(uint256 ) external {

    }

    // Auctioneer calls to claim the highest bid
    function claimAuctioneer(uint256 auctionId) external {
        
    }

    // Winning bidder calls to claim NFT
    // They are refunded the obfuscation amount
    function claimWinningBidder(uint256 auctionId) external {

    }

    // Losing bidder calls to reclaim all ETH sent
    function claimLosingBidder(uint256 auctionId) external {

    }

    function _isPuzzleSolved(Puzzle memory puzzle) internal pure returns (bool) {
        return puzzle.p != 0 && puzzle.q != 0 && puzzle.d != 0;
    }
}