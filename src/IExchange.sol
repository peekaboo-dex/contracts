// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExchange {

    struct Puzzle {
        bytes input;
        uint256 p;
        uint256 q;
        uint256 d;
    }

    enum AuctionState {
        OPEN,
        CLOSED,
        FINALIZED
    }

    struct Auction {
        uint256 auctionId;
        address auctioneer;
        address tokenAddress;
        uint256 tokenId;
        bytes publicKey;
        Puzzle puzzle;
        address currentHighestBidder;
        address winner;
        AuctionState state;
    }

    struct SealedBid {
        uint256 value;
        uint256 ethSent;
    }

    // difficulty is the time parameter to the t-squarings VDF
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed auctioneer,
        address tokenAddress,
        uint256 tokenId,
        bytes publicKey,
        bytes puzzle
    );

    event AuctionPuzzleSolved(
        uint256 indexed auctionId,
        uint256 p,
        uint256 q,
        uint256 d
    );

    event BidCommitted(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 sealedBid,
        uint256 ethSent
    );

    event BidRevealed(
        uint256 indexed auctionId, 
        address indexed bidder,
        uint256 bid,
        uint256 obfuscation,
        bool isCurrentHighestBid,
        bool isValidBid
    );

    event ClaimByAuctioneer(
        uint256 indexed auctionId,
        uint256 bid
    );

    event ClaimByWinningBidder(
        uint256 indexed auctionId,
        uint256 refund
    );

    event ClaimByLosingBidder(
        uint256 indexed auctionId,
        uint256 refund
    );

    // Creates an auction for an NFT.
    function createAuction(address tokenAddress, uint256 tokenId, bytes calldata publicKey, bytes calldata puzzle) external;

    // Solves the auction's puzzle. The solution is the secret key (p,q,d).
    // Once this is called anyone can decrypt the bids using the emitted event.
    function solveAuctionPuzzle(uint256 auctionId, uint256 p, uint256 q, uint256 d) external;

    // Bidder commits to their bid for a given auction.
    // The bid is encrypted with the auction's public key.
    // msg.value = bid + obfuscation
    function commitBid(uint256 auctionId, uint256 sealedBid) external payable;

    // Reveal bid for this bidder
    function revealBid(uint256 auctionId, address bidder) external;

    // Auctioneer calls to claim the highest bid
    function claimAuctioneer(uint256 auctionId) external;

    // Winning bidder calls to claim NFT
    // They are refunded the obfuscation amount
    function claimWinningBidder(uint256 auctionId) external;

    // Losing bidder calls to reclaim all ETH sent
    function claimLosingBidder(uint256 auctionId) external;
}