// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IExchange.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Exchange is IExchange {

    // Current auction Id
    uint256 public currentAuctionId;

    // 

    // Creates an auction for an NFT.
    function createAuction(address tokenAddress, uint256 tokenId, bytes calldata publicKey, bytes calldata puzzle) external {
        // Transfer token into exchange
        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this));
    }

    // Solves the auction's puzzle. The solution is the secret key (p,q,d).
    // Once this is called anyone can decrypt the bids using the emitted event.
    function solveAuctionPuzzle(uint256 auctionId, uint256 p, uint256 q, uint256 d) external {
        
    }

    // Bidder commits to their bid for a given auction.
    // The bid is encrypted with the auction's public key.
    // msg.value = bid + obfuscation
    function commitBid(uint256 auctionId, uint256 sealedBid) external payable {

    }

    // Reveal bid for this bidder
    function revealBid(uint256 auctionId, address bidder) external {

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
}