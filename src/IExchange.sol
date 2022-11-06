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
        uint256 publicKey;
        Puzzle puzzle;
        uint256 puzzleSolvedTimestamp;
        address currentHighestBidder;
        AuctionState state;
    }

    struct SealedBid {
        uint256 value;
        uint256 ethSent;
    }

    struct UnsealedBid {
        uint256 bid;
        uint256 obfuscation;
    }

    // difficulty is the time parameter to the t-squarings VDF
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed auctioneer,
        address tokenAddress,
        uint256 tokenId,
        uint256 publicKey,
        bytes puzzle
    );

    event AuctionClosed(
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

    event AuctionFinalized(
        uint256 indexed auctionId,
        address winner,
        uint256 winningBid
    );

    event Refund(
        uint256 indexed auctionId,
        uint256 amount
    );

    // Creates an auction for an NFT. Returns auction id.
    function createAuction(address tokenAddress, uint256 tokenId, uint256 publicKey, bytes calldata puzzle) external returns (uint256);

    // Close the auction by submitting the solution to the auction's puzzle.
    // The solution is the secret key (p,q,d).
    // Once this is called anyone can decrypt the bids using the emitted event.
    function closeAuction(uint256 auctionId, uint256 p, uint256 q, uint256 d) external;

    // Bidder commits to their bid for a given auction.
    // The bid is encrypted with the auction's public key.
    // msg.value = bid + obfuscation
    function commitBid(uint256 auctionId, uint256 sealedBid) external payable;

    // Reveal bid for this bidder
    function revealBid(uint256 auctionId, address bidder) external returns (uint256);

    function finalizeAuction(uint256 auctionId) external;

    function claimRefund(uint256 auctionId) external;
}