// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
* @title ERC1155 token for XLR8 Components
* @author JJZFIVE
*/

// Just one 1155 contract that holds all components 
// (i.e. one opensea page for all components), and one 721 contract for full cars (i.e. one opensea page for full cars)
// And in the 1155 contract we just keep track of which ID # corresponds to which component type

// TODO: Keep in mind that we'll be using this contract for the next seasons

contract XLR8Components is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; // Keeps track of token id's released
    using Strings for uint256;

    address public FullCarContract; // So we can approve access for all
    uint256 private _lastSeasonTotalNumComponents; // Use this to determine if an id is in the newest season

    string public name;
    string public symbol;   
    string _prerevealURI; 
    uint256 public currentSeason;

    mapping(uint256 => bool) public seasonToRevealed;

    // Mapping of component ID to the type: 0: model, 1: wrap, 2: engine
    mapping(uint256 => uint256) public idToComponentType;

    // Mapping of component id => max supply of that id
    mapping(uint256 => uint256) public idToMaxSupply;

    // Mapping of the season to that season's base URI 
    mapping(uint256 => string) public seasonToBaseURI;

    // Mapping of the token Id to its season (for uri reasons)
    mapping(uint256 => uint256) public idToSeason;

    // Mapping of season to the timestamp of the reveal
    // mapping (uint256 => uint256) public seasonToRevealTimestamp;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _season0baseuri,
        uint256[] memory _maxSupplies, 
        uint256[] memory _componentTypes,
        string memory _season0prerevealuri
    ) ERC1155(_season0baseuri) {
        require(_maxSupplies.length == _componentTypes.length, "_maxSupplies and _componentTypes must be the same length");

        name = _name;
        symbol = _symbol;

        currentSeason = 0;
        seasonToRevealed[currentSeason] = false;
        seasonToBaseURI[currentSeason] = _season0baseuri;

        // Same code as addNewComponents, but wanted function parameter to be calldata,
        // and not compatible with constructor memory paramter
        _lastSeasonTotalNumComponents = _tokenIds.current();
        seasonToRevealed[currentSeason] = false; 
        _prerevealURI = _season0prerevealuri;

        uint256 tokenId;
        for (uint i = 0; i < _maxSupplies.length; i++) {
            tokenId = _tokenIds.current();
            idToMaxSupply[tokenId] = _maxSupplies[i];
            idToComponentType[tokenId] = _componentTypes[i];

            idToSeason[tokenId] = currentSeason;

            require(_maxSupplies[i] > 0, "Max supply cannot be negative");
            require(_componentTypes[i] >= 0 && _componentTypes[i] <= 2, "Invalid component types");

            _tokenIds.increment();
        }

        
    }

    /* 
    * @notice Sets maxSupplies for new ids and sets new prereveal uri
    * 
    * @param _maxSupplies the card id to return metadata for
    * @param _uri the new season's prereveal uri
    */
    function addNewSeason(
        uint256[] calldata _maxSupplies,
        uint256[] calldata _componentTypes,
        string calldata _seasonBaseUri,
        string calldata _newPrerevealUri ) public onlyOwner {
        require(_maxSupplies.length == _componentTypes.length, "_maxSupplies and _componentTypes must be the same length");


        _lastSeasonTotalNumComponents = _tokenIds.current();
        currentSeason += 1;
        seasonToRevealed[currentSeason] = false; 
        seasonToBaseURI[currentSeason] = _seasonBaseUri;
        _prerevealURI = _newPrerevealUri;

        uint256 tokenId;
        for (uint i = 0; i < _maxSupplies.length; i++) {
            tokenId = _tokenIds.current();
            idToMaxSupply[tokenId] = _maxSupplies[i];
            idToComponentType[tokenId] = _componentTypes[i];

            idToSeason[tokenId] = currentSeason;

            require(_maxSupplies[i] > 0, "Max supply cannot be negative");
            require(_componentTypes[i] >= 0 && _componentTypes[i] <= 2, "Invalid component types");

            _tokenIds.increment();
        }
        
    }

    function revealNewestSeason() public onlyOwner {
        require(!seasonToRevealed[currentSeason], "This season's already been revealed!");
        seasonToRevealed[currentSeason] = true;
    }

    // Component contract published before full car contract, so upload here
    // Sets approval for the car contract to transfer components to itself during fusing
    function setCarContractAddress(address _address) public onlyOwner {
        FullCarContract = _address;
        setApprovalForAll(FullCarContract, true); // Allows car fusing function to call transferFrom
    }

    function isInNewestSeason(uint256 _id) internal view returns (bool) {
        return _id >= _lastSeasonTotalNumComponents;
    }

    

    // TODO: General mint function (exclude whitelist for now)
    // Must check if the id # is below the _tokenIds counter and has not reached maxsupply


    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
     function exists(uint256 id) public view returns (bool) {
        return idToMaxSupply[id] > 0;
    }

    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        // If it's in the newest season and the reveal hasn't happened yet
        if (isInNewestSeason(_id) && !seasonToRevealed[currentSeason]) {
            return _prerevealURI;
        }

        return string(abi.encodePacked(seasonToBaseURI[idToSeason[_id]], Strings.toString(_id)));
    }
}