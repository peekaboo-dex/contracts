// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PeekabooNFT is ERC721 {

    constructor() ERC721("PeekabooNFT", "URI") {}
}