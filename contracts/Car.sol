// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./IXLR8Minter.sol";
import "./ComponentIERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Car is ERC721URIStorage, Ownable, ChainlinkClient {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // For updating the offset in this contract
    uint256 public offset;
    IXLR8Minter XLR8Minter;
    uint256 public maxComponentSupply;

    // Component contracts for calling ownerOf
    ComponentIERC721 wheelContract;
    ComponentIERC721 engineContract;
    ComponentIERC721 buildContract;
    ComponentIERC721 wrappingContract;

    // For Chainlink
    using Chainlink for Chainlink.Request;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    string private FuserAPI;

    struct Components {
        uint32 wheel_id; // 2^32 = 4294967296. We won't have anywhere near that # of components
        uint32 engine_id;
        uint32 build_id;
        uint32 wrapping_id;
    }

    mapping(uint256 => Components) public carIdToComponents; // Car token_id to the components struct that went into it
    mapping(bytes32 => uint256) public requestIdToTokenId; // Fulfill function adds tokenURI, but asynchronous - need to keep track of request to tokenID

    Counters.Counter private _tokenId;

    constructor(
    address _oracle, 
    address _XLR8Minter, 
    address _wheelContract,
    address _engineContract,
    address _buildContract,
    address _wrappingContract,
    uint256 _maxComponentSupply
    ) ERC721("XLR8 Full Car", "XLR8_FC") {
        XLR8Minter = IXLR8Minter(_XLR8Minter);
        wheelContract = ComponentIERC721(_wheelContract);
        engineContract = ComponentIERC721(_engineContract);
        buildContract = ComponentIERC721(_buildContract);
        wrappingContract = ComponentIERC721(_wrappingContract);
        maxComponentSupply = _maxComponentSupply;

        setPublicChainlinkToken();
        setChainlinkOracle(_oracle);
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8; // TAKEN FROM EXAMPLE, CHANGE
        jobId = "d5270d1c311941d0b08bead21fea7747"; // TAKEN FROM EXAMPLE, CHANGE
        fee = 0.1 * 10 ** 18; // (Varies by network and job) // TAKEN FROM EXAMPLE, CHANGE 
    }

    // Be sure to add the offset when pushing the id's to the API call so correct metadata is used
    // Check if these id's are owned by the msg.sender
    function fuseIntoCar(uint256 _wheelId, uint256 _engineId, uint256 _buildId, uint256 _wrappingId) public {
        // check if the id's are owned by the msg.sender
        require(wheelContract.ownerOf(_wheelId) == msg.sender, "Sender doesn't own wheels");
        require(engineContract.ownerOf(_engineId) == msg.sender, "Sender doesn't own engine");
        require(buildContract.ownerOf(_buildId) == msg.sender, "Sender doesn't own build");
        require(wrappingContract.ownerOf(_wrappingId) == msg.sender, "Sender doesn't own wrapping");
        require(offset != 0, "Offset hasn't been determined yet by the minting contract");

        // TODO: Add transfering of the components
        safeTransferFrom(msg.sender, address(this), _wheelId);
        safeTransferFrom(msg.sender, address(this), _engineId);
        safeTransferFrom(msg.sender, address(this), _buildId);
        safeTransferFrom(msg.sender, address(this), _wrappingId);

        uint256 wheelMetadataId = (_wheelId + offset) % maxComponentSupply;
        uint256 engineMetadataId = (_engineId + offset) % maxComponentSupply;
        uint256 buildMetadataId = (_buildId + offset) % maxComponentSupply;
        uint256 wrappingMetadataId = (_wrappingId + offset) % maxComponentSupply;

        // mint the nft, but set storage later
        // call the chainlink client
        bytes32 _requestId = ChainlinkCall(wheelMetadataId, engineMetadataId, buildMetadataId, wrappingMetadataId); // if this function is asynchronous this might not work
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();
        requestIdToTokenId[_requestId] = tokenId;
        _mint(msg.sender, tokenId);

        // in the fulfill function, set the token URI of the newly minted token id
    }

    // TODO: Update this and its name
    function ChainlinkCall(uint256 _wheelMetadataId, uint256 _engineMetadataId, uint256 _buildMetadataId, uint256 _wrappingMetadataId) internal returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Generate new API request URL
        string memory apiRequest = string(abi.encodePacked(FuserAPI, _wheelMetadataId.toString(), "/", _engineMetadataId.toString(), "/", _buildMetadataId.toString(), "/", _wrappingMetadataId.toString()));
        request.add("get", apiRequest);
        request.add("path", "tokenURI");
        
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    /**
    * Receive the response in the form of string
    */ 
    function fulfill(bytes32 _requestId, bytes32 _tokenURI) public recordChainlinkFulfillment(_requestId)
    {
        string memory tokenURI = bytes32ToString(_tokenURI);
        uint256 tokenId = requestIdToTokenId[_requestId];
        _setTokenURI(tokenId, tokenURI); 
    }

    function destructCar(uint256 _carTokenId) public {
        require(ownerOf(_carTokenId) == msg.sender, "The sender does not own that car!");
        _burn(_carTokenId);

        // Transfer the correct components back to the sender
        Components storage components = carIdToComponents[_carTokenId];
        uint32 wheel_id = components.wheel_id;
        uint32 engine_id = components.engine_id;
        uint32 build_id = components.build_id;
        uint32 wrapping_id = components.wrapping_id;
        _transfer(address(this), msg.sender, wheel_id);
        _transfer(address(this), msg.sender, engine_id);
        _transfer(address(this), msg.sender, build_id);
        _transfer(address(this), msg.sender, wrapping_id);
    }


    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function updateChainlinkOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function updateChainlinkJobId(bytes32 _jobId) public onlyOwner {
        jobId = _jobId;
    }

    function updateChainlinkFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function updateOffset() public {
        offset = XLR8Minter.offset();
    }

}