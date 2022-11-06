// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PeekabooNFT is ERC721 {

    constructor() ERC721("PeekabooNFT", "URI") {}

    /**
     * @dev Override safeTransferFrom for the auction. 
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        // No require for demo 
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }
}