// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./XLR8Components.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

/*
* @title ERC1155 token for XLR8 Components
* @author JJZFIVE
*/

// TODO: Ensure this contract is funded with enough LINK to fulfill the Chainlink requests

contract XLR8Cars is ERC721URIStorage, Ownable, ChainlinkClient {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenId;

    XLR8Components public xlr8components;

    // For Chainlink
    using Chainlink for Chainlink.Request;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    string private FuserAPI;

    struct Components {
        uint32 model_id; // 2^32 = 4294967296. We won't have anywhere near that # of components
        uint32 wrap_id;
        uint32 engine_id;
    }

    mapping(uint256 => Components) public carIdToComponents; // Car token_id to the components struct that went into it
    mapping(bytes32 => uint256) public requestIdToTokenId; // Fulfill function adds tokenURI, but asynchronous - need to keep track of request to tokenID


    constructor(
    address _oracle,
    bytes32 _jobId,
    uint256 _oracleFee,
    address _XLR8Components
    ) ERC721("XLR8", "XLR8_CARS") {
        xlr8components = XLR8Components(_XLR8Components);

        setPublicChainlinkToken();
        setChainlinkOracle(_oracle);
        oracle = _oracle;
        jobId = _jobId;
        fee = _oracleFee;
    }

    // Idea: fusing multiple cars at once with batches? 
    function fuseIntoCar(uint256 _modelId, uint256 _wrapId, uint256 _engineId) public {
        // Check if the id's are owned by the msg.sender
        require(xlr8components.balanceOf(msg.sender, _modelId) > 0, "Sender doesn't own model");
        require(xlr8components.balanceOf(msg.sender, _wrapId) > 0, "Sender doesn't own wrap");
        require(xlr8components.balanceOf(msg.sender, _engineId) > 0, "Sender doesn't own engine");

        // TODO: make sure you have 1 of each component

        xlr8components.safeTransferFrom(msg.sender, address(this), _modelId, 1, "");
        xlr8components.safeTransferFrom(msg.sender, address(this), _wrapId, 1, "");
        xlr8components.safeTransferFrom(msg.sender, address(this), _engineId, 1, "");

        // Call the Chainlink Node
        bytes32 _requestId = ChainlinkCall(_modelId, _wrapId, _engineId);

        // Mint the NFT
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();
        requestIdToTokenId[_requestId] = tokenId;
        _mint(msg.sender, tokenId);
    }

    // TODO: Update this
    function ChainlinkCall(uint256 _modelId, uint256 _wrapId, uint256 _engineId) internal returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // TODO: is chainlink a post request or something?
        // Generate new API request URL
        string memory apiRequest = string(abi.encodePacked(FuserAPI, _modelId.toString(), "/", _wrapId.toString(), "/", _engineId.toString()));
        request.add("get", apiRequest);
        request.add("path", "tokenURI");
        
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    // TODO: update this
    /**
    * Receive the response in the form of string
    */ 
    function fulfill(bytes32 _requestId, bytes32 _tokenURI) public recordChainlinkFulfillment(_requestId)
    {
        string memory tokenURI = bytes32ToString(_tokenURI);
        uint256 tokenId = requestIdToTokenId[_requestId];
        _setTokenURI(tokenId, tokenURI); 
    }

    // Destructs the car back into its components. Burns the car
    function destructCar(uint256 _carTokenId) public {
        require(ownerOf(_carTokenId) == msg.sender, "The sender does not own that car!");
        _burn(_carTokenId);

        // Transfer the correct components back to the sender
        Components storage components = carIdToComponents[_carTokenId];
        uint32 model_id = components.model_id;
        uint32 wrap_id = components.wrap_id;
        uint32 engine_id = components.engine_id;

        xlr8components.safeTransferFrom(address(this), msg.sender, model_id, 1, "");
        xlr8components.safeTransferFrom(address(this), msg.sender, wrap_id, 1, "");
        xlr8components.safeTransferFrom(address(this), msg.sender, engine_id, 1, "");
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
}