// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Deploy first, before the xlr8 minter contract address
contract ComponentNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Strings for uint256;

    address public XLR8Minter;
    address public Car;
    uint256 public maxSupply;

    string public baseURI; 
    uint256 public offset = 0;

    string public constant PROVENANCE = ""; // Hardcode this at launch

    event NFTCreated (
        uint256 indexed tokenId,
        address indexed creatorAddress
    );

    constructor(uint256 _maxSupply) ERC721("REPLACE ME WITH NAME", "REPLACE ME WITH TICKER") {
        maxSupply = _maxSupply;
        baseURI = "Pre-reveal mystery URI here"; // Pre-reveal mystery URI
    }

    function setCarAddress(address _address) public onlyOwner {
        Car = _address;
        setApprovalForAll(Car, true); // Allows car fusing function to call transferFrom
    }

    function setXLR8MinterAddress(address _address) public onlyOwner {
        XLR8Minter = _address;
    }

    modifier onlyMinter() {
        require(msg.sender == XLR8Minter, "Only the XLR8 Minter contract can mint components");
        _;
    }

    function mintFromMinter(address _msgSender) public onlyMinter returns (bool) {
        _tokenIds.increment();
        uint _tokenId = _tokenIds.current();
        require(_tokenId < maxSupply, "Max supply already reached");

        _safeMint(_msgSender, _tokenId);
        emit NFTCreated(_tokenId, _msgSender);

        return true;
    }

    // Credit to Vox Collectibles team for this offset method
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (offset == 0) {
            return bytes(baseURI).length > 0 ? baseURI : "";
        } else {
            uint256 newId = (tokenId + offset) % maxSupply;
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, newId.toString())) : "";
        }
    }

    // Must discuss with harkness team if we want this to be a 1 time thing
    function setBaseURI(string calldata _baseURI) internal onlyOwner {
        baseURI = _baseURI;
    }

    function setOffset(uint256 _offset) public onlyMinter {
        offset = _offset;
    }

}