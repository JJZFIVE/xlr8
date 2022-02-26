// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ModifiedIERC721.sol";


// Deploy second, after the xlr8 component contracts
contract XLR8Minter is Ownable {
    uint256 public openMintingTime; // Block timestamp of when the minting opens
    mapping(address => bool) public whitelisted; // Address => is the address whitelisted to mint?
    uint256 public mintingFee;
    ModifiedIERC721 wheelContract;
    ModifiedIERC721 engineContract;
    ModifiedIERC721 buildContract;
    ModifiedIERC721 wrappingContract;

    constructor(uint256 _openMintingTime, 
    uint256 _mintingFee,
    address _wheelContract,
    address _engineContract,
    address _buildContract,
    address _wrappingContract
    ) {
        openMintingTime = _openMintingTime;
        mintingFee = _mintingFee;
        wheelContract = ModifiedIERC721(_wheelContract);
        engineContract = ModifiedIERC721(_engineContract);
        buildContract = ModifiedIERC721(_buildContract);
        wrappingContract = ModifiedIERC721(_wrappingContract);
    }

    function updateMintingFee(uint256 _fee) public onlyOwner {
        mintingFee = _fee;
    }

    function mint4Components() public payable {
        require(whitelisted[msg.sender] == true, "The user is not whitelisted to mint");
        require(msg.value >= mintingFee, "The value submitted is less than the minting fee");
        // Do randomness here
        // Incomplete - mints one of each
        wheelContract.mintFromMinter();
        engineContract.mintFromMinter();
        buildContract.mintFromMinter();
        wrappingContract.mintFromMinter();
        
    }

}