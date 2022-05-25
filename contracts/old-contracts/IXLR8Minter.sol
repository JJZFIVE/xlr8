// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXLR8Minter {
    // Just so we can call offset() in Car.sol
    function offset() external returns(uint256);
}