// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

/*
* @title ERC1155 token for XLR8 Components
* @author JJZFIVE
*/

// Just one 1155 contract that holds all components 
// (i.e. one opensea paCge for all components), and one 721 contract for full cars (i.e. one opensea page for full cars)
// And in the 1155 contract we just keep track of which ID # corresponds to which component type

// TODO: Keep in mind that we'll be using this contract for the next seasons

contract XLR8Components is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; // Keeps track of token id's released
    using Strings for uint256;

    address public FullCarContract; // So we can approve access for all

    string public name;
    string public symbol;   
    uint256 public currentSeason;

    struct Season {
        bool revealed;
        uint256 maxMintPerAddress;
        uint256 mintingFee;
        uint256 lastSeasonTotalNumComponents; // Use this to determine if an id is in the newest season
        string baseUri;
        string prerevealUri;
    }

    struct Component {
        uint8 componentType; // 0: model, 1: wrap, 2: engine
        uint8 season;
        uint256 maxSupply;
        uint256 numberMinted;
    }

    mapping(uint256 => Season) public seasonToSeasonData; // Season # to the Season struct data
    mapping(uint256 => mapping(address => uint256)) public seasonToAddressToNumberOfMints; // Season # to address to # of times they've minted in that season
    mapping(uint256 => Component) public idToComponent;
    

    // Address of last person who minted to factor into the mint randomness function
    address private _lastAddressToMint; 

    // Mapping of season to the timestamp of the reveal
    // mapping (uint256 => uint256) public seasonToRevealTimestamp;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _season0baseuri,
        string memory _season0prerevealuri,
        uint256[] memory _maxSupplies, 
        uint256[] memory _componentTypes,
        uint256 _maxMintForSeason0,
        uint256 _season0mintingFee
    ) ERC1155(_season0baseuri) {
        require(_maxSupplies.length == _componentTypes.length, "_maxSupplies and _componentTypes must be the same length");

        name = _name;
        symbol = _symbol;

        currentSeason = 0;
        seasonToSeasonData[currentSeason] = Season(false, _maxMintForSeason0, _season0mintingFee, 0, _season0baseuri, _season0prerevealuri);

        _lastAddressToMint = msg.sender; // Arbitrarily chose this, not really important

        // Same code as addNewComponents, but wanted function parameter to be calldata,
        // and not compatible with constructor memory paramter
        uint256 tokenId;
        for (uint i = 0; i < _maxSupplies.length; i++) {
            tokenId = _tokenIds.current();
            // Creates a new component and puts it in the mapping
            idToComponent[tokenId] = Component(_componentTypes[i], currentSeason, _maxSupplies[i], 0);

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
        string calldata _newPrerevealUri ,
        uint256 _maxMintForSeason,
        uint256 _mintingFee ) public onlyOwner {
        require(_maxSupplies.length == _componentTypes.length, "_maxSupplies and _componentTypes must be the same length");

        currentSeason += 1;
        uint256 lastSeasonTotalNumComponents = _tokenIds.current();

        seasonToSeasonData[currentSeason] = Season(false, _maxMintForSeason, _mintingFee, lastSeasonTotalNumComponents, _seasonBaseUri, _newPrerevealUri);

        uint256 tokenId;
        for (uint i = 0; i < _maxSupplies.length; i++) {
            tokenId = _tokenIds.current();
            // Creates a new component and puts it in the mapping
            idToComponent[tokenId] = Component(_componentTypes[i], currentSeason, _maxSupplies[i], 0);

            require(_maxSupplies[i] > 0, "Max supply cannot be negative");
            require(_componentTypes[i] >= 0 && _componentTypes[i] <= 2, "Invalid component types");

            _tokenIds.increment();
        }
        
    }

    function revealNewestSeason() public onlyOwner {
        require(!seasonToSeasonData[currentSeason].revealed, "This season's already been revealed!");
        seasonToSeasonData[currentSeason].revealed = true;
    }

    // Component contract published before full car contract, so upload here
    // Sets approval for the car contract to transfer components to itself during fusing
    function setCarContractAddress(address _address) public onlyOwner {
        FullCarContract = _address;
        setApprovalForAll(FullCarContract, true); // Allows car fusing function to call transferFrom
    }

    function isInNewestSeason(uint256 _id) internal view returns (bool) {
        return _id >= seasonToSeasonData[currentSeason].lastSeasonTotalNumComponents;
    }


    function getRandomNumber(uint256 _balanceOfNum, uint256 _previousRandNum) internal view returns (uint256) {
        uint256 numInCurrentSeason = _tokenIds.current() - seasonToSeasonData[currentSeason].lastSeasonTotalNumComponents;
        return uint256(keccak256(abi.encodePacked(_balanceOfNum, _previousRandNum, _lastAddressToMint, block.timestamp))) % numInCurrentSeason;
    }

    

    // TODO: General mint function (exclude whitelist for now)
    // Must check if the id # is below the _tokenIds counter and has not reached maxsupply
    // Set the _lastAddressToMint = msg.sender
    function mintComponent(uint256 amount) public payable {
        require(tx.origin == msg.sender);
        require(msg.value >= amount * seasonToSeasonData[currentSeason].mintingFee, "Incorrect payment");

        seasonToAddressToNumberOfMints[currentSeason][msg.sender] = 0; // TODO: Maybe take this out, might init to 0 anyways

        uint256 mintId = 0;
        for (uint i = 0; i < amount; i++) {
            uint balanceOfpreviousMintId = balanceOf(msg.sender, mintId);
            mintId = getRandomNumber(balanceOfpreviousMintId, mintId);

            // TODO: check if randNum's been minted out, and if so, increment until it settles in
            

            _mint(msg.sender, mintId, 1, "");
            seasonToAddressToNumberOfMints[currentSeason][msg.sender] += 1;
        }
        


    }


    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view returns (bool) {
        return idToComponent[id].maxSupply > 0;
    }

    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        // If it's in the newest season and the reveal hasn't happened yet
        if (isInNewestSeason(_id) && !seasonToSeasonData[currentSeason].revealed) {
            return seasonToSeasonData[currentSeason].prerevealUri;
        }

        return string(abi.encodePacked(seasonToSeasonData[idToComponent[_id].season].baseUri, Strings.toString(_id)));
    }
}