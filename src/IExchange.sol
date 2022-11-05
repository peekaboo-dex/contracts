// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExchange {


    /// https://github.com/paulrberg/prb-math/tree/main/contracts 

    // difficulty is the time parameter to the t-squarings VDF
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed auctioneer,
        address tokenAddress,
        uint256 tokenId,
        uint256 difficulty
    );

    event BidCommitted(
        uint256 indexed auctionId,
        address indexed bidder,
        bytes32 sealedBid,
        uint256 ethSent
    );

    event BidRevealed(
        uint256 indexed auctionId, 
        address indexed bidder,
        uint256 bid,
        uint256 obfuscationAmount
    );

    event ClaimByAuctioneer(
        uint256 indexed auctionId,
        uint256 bid
    );

    event ClaimByBidder(
        uint256 indexed auctionId,
        uint256 refund,
        bool isWinner
    );

    // Creates an auction for an NFT.
    // tokenAddress of NFT
    // tokenId of NFT
    // Emits AuctionCreated() event
    function CreateAuction(address tokenAddress, uint256 tokenId, uint256 difficulty, uint256 bidPeriodInBlocks) external;

    // Bidder commits to their bid for a given auction.
    // auctionId of corresponding auction.
    // sealedBid is bid XOR keccak256((VDF))
    //           ... bid should be obfuscated so if it's like 1 ETH it should be 0.999999999236423784623784 XOR keccak256(VDF)
    // msg.value Send bid amount plus some obfuscation amount, which is refunded by `claimBidder`.
    // Emits BidCommitted() event

    // Suppose they want to bid 1 ETH.
    // We obfuscate it to like 0.999999999236423784623784
    // We then generate the challenge (aa in the example; for us it'll be a random bytes32)
    // We then compute the VDF = `vdf-cli challenge difficulty`, difficulty comes from the CreateAuction event
    // sealedBid = bid XOR keccak256(VDF)
    // But then the user  further ubfuscates byt sending in ANY amount with their bid
    // bid = 0.999999999236423784623784 + 234 ETH
    function CommitBid(uint256 auctionId, bytes32 sealedBid, bytes32 challenge) external payable;

    // Only need to reveal the winning bid.
    // Only the winning bid needs to be revealed.
    // This will assert `bid XOR keccak256(VDF) == sealedBid`

    // Read the challenge from the BidCommitted event
    // Read the difficulty from the AuctionCreated event
    // Compute VDF = `vdf-cli challenge difficulty`
    // bid = sealedBid XOR keccak256(VDF)
    function RevealBid(address bidder, uint256 bid, bytes calldata vdf, uint256 obfuscationAmount) external;

    // 
    // diffiulty is 2 minutes.
    // Length has to be 2 x 2 minutes. Because someone could commit theirs at the last second.

    function claimAuctioneer(uint256 auctionId) external;

    // 
    function claimBidder(uint256 auctionId) external;
}