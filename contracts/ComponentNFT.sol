// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Deploy first, before the xlr8 minter contract address
contract ComponentNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public XLR8Minter;

    event NFTCreated (
        uint256 indexed tokenId
    );

    constructor() ERC721("REPLACE ME WITH NAME", "REPLACE ME WITH TICKER") {}

    function setXLR8MinterAddress(address _address) public onlyOwner {
        XLR8Minter = _address;
    }

    modifier _onlyMinter() {
        require(msg.sender == XLR8Minter, "Only the XLR8 Minter contract can mint components");
        _;
    }

    function mintFromMinter() public _onlyMinter returns (uint256 tokenId) {
        _tokenIds.increment();
        uint _tokenId = _tokenIds.current();
        _safeMint(msg.sender, _tokenId);
        string memory tokenURI = ""; // FIND A WAY to GRAB THIS
        _setTokenURI(_tokenId, tokenURI);
        emit NFTCreated(_tokenId);
        return _tokenId;
    }


}