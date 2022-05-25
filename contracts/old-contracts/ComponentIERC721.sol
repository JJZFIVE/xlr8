// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

// Modified by Joe 

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ComponentIERC721 is IERC721 {

    // NEW: mintFromMinter
    function mintFromMinter(address _msgSender) external returns (bool);

    // NEW: setOffset
    function setOffset(uint256 _offset) external;

    // NEW: maxSupply
    function maxSupply() external returns (uint256);

    // NEW: NFTCreated
    event NFTCreated(uint256 indexed tokenId, address indexed creatorAddress);
}