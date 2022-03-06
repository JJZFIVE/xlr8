// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ComponentIERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol"; 
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IXLR8Minter.sol";

// Minting contract calls VRF once, passes same offset to all components

// Deploy second, after the xlr8 component contracts
contract XLR8Minter is Ownable, VRFConsumerBase, IXLR8Minter {
    using Counters for Counters.Counter;
    
    // if you want to get fancy, merkle proofs/roots are becoming more commonly used for whitelisting, more efficient i believe than manually adding a bunch of people or loading a bunch of addresses into the constructor 
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public addressToNumberOfMints;

    ComponentIERC721 wheelContract;
    ComponentIERC721 engineContract;
    ComponentIERC721 buildContract;
    ComponentIERC721 wrappingContract;

    string public constant PROVENANCE = ""; // Hardcode this at launch

    // For Chainlink VRF
    bytes32 internal keyHash;
    bytes32 internal vrfRequestId;
    uint256 public offset;
    uint256 internal vrfFee = 2 * 10 ** 18; // From VOX Collectibles contract, double check this

    // For Minting
    uint256 public mintingFee;
    uint256 public saleStartTime; // Block timestamp of when the minting opens
    
    // remember - private variables are not truly private, so someone could discover this value if technical. 
    Counters.Counter private _mintingCounter; // Range: [0, 8)
    bool public revealBool = false;

    // Double check the VRFConsumerBase links - taken from vox collectibles
    constructor(uint256 _saleStartTime, 
    uint256 _mintingFee,
    address _wheelContract,
    address _engineContract,
    address _buildContract,
    address _wrappingContract
    ) 
    // probably a good idea to not hardcode this but rather add as param in constructor to allow for easy testnet configuration
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
    ) {
        saleStartTime = _saleStartTime;
        mintingFee = _mintingFee * (1 ether); // Minting Fee passed in must be the ether value

        wheelContract = ComponentIERC721(_wheelContract);
        engineContract = ComponentIERC721(_engineContract);
        buildContract = ComponentIERC721(_buildContract);
        wrappingContract = ComponentIERC721(_wrappingContract);
    }

    function updateMintingFee(uint256 _fee) public onlyOwner {
        mintingFee = _fee;
    }

    // presale mint or give our team a certain number of initial parts
    // function presaleMint() public payable {}

    // It's assumed that max supplies for each component are equal
    // saying it again here for repetition (also it's been a while since i've looked at the contracts) - this implementation is currently just randomness by obfuscation. 
    // if you're looking to save $ on VRF calls do some pseudorandom thing like a hash of block.difficult, block.number, and the person's wallet 
    // ^^ something like that make it a lot more difficult for someone to manipulate to get a specific part
    function mintRandomComponent() public payable {
        // add: require(tx.origin == msg.sender) to prevent smart contracts (and therefore bots) from minting.
        // https://jbecker.dev/research/adidas-originals/
        require(block.timestamp >= saleStartTime, "Sale has not started");
        require(msg.value >= mintingFee, "The value submitted is less than the minting fee");
        require(addressToNumberOfMints[msg.sender] < 4, "Sender has already minted the maximum of 4 components"); // Each address can only mint up to 4 components

        _mintingCounter.increment();
        uint256 _mintingNum = _mintingCounter.current();

        if (_mintingNum > 7) {
            _mintingCounter.reset();
            _mintingNum = _mintingCounter.current();
        }

        // Wheel
        if (_mintingNum == 0 || _mintingNum == 7) {
            require(wheelContract.mintFromMinter(msg.sender), "Max supply already reached");
        }
        // Engine
        else if (_mintingNum == 1 || _mintingNum == 2) {
            require(engineContract.mintFromMinter(msg.sender), "Max supply already reached");
        }
        // Build
        else if (_mintingNum == 3 || _mintingNum == 6) {
            require(buildContract.mintFromMinter(msg.sender), "Max supply already reached");
        }
        // Wrapping
        else if (_mintingNum == 4 || _mintingNum == 5) {
            require(wrappingContract.mintFromMinter(msg.sender), "Max supply already reached");
        }
        // Something's gone wrong if this block executes
        // not a fan of this pattern - it's basically saying you don't trust the code lol
        // it'll never exceed 7 based off the first condition so this will never happen 
        // but if you do want to keep it you could just do revert(), no need for the falsy condition to throw an error 
        else {
            require(1 == 0, "Something's wrong with _mintingCounter");
        }

        addressToNumberOfMints[msg.sender] += 1;
        
    }

    // Maybe add a locking timestamp function so even the owner can't update. Or maybe not
    // function setBaseURI(string calldata _baseURI) public onlyOwner {}

    // function swapETHForUSDC() public onlyOwner {}

    // function swapUSDCforETH() public onlyOwner {}

    function setRevealBool() public onlyOwner {
        require(!revealBool, "RevealBool has already been set to true");
        revealBool = true;
    }
    
    // do you want this to have a modifier - onlyOwner? 
    // what's the difference between reveal and setRevealBool?
    function reveal() public {
        require(offset == 0, "Offset is already set");
        require(vrfRequestId == 0, "Randomness already requested");
        require(revealBool, "Can not be revealed yet");
        vrfRequestId = requestRandomness(keyHash, vrfFee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(offset == 0, "Offset is already set");
        
        // I don't think you need to check the requestId, as this function is called by Chainlink's contracts automatically via rawFulfillRandomness() 
        require(vrfRequestId == requestId, "VRF Request Id must match");
        uint256 componentMaxSupply = wheelContract.maxSupply();
        offset = (randomness % (componentMaxSupply - 1)) + 1;
        if (offset == 0) {
            offset = 1;
        }

        // instead of four external calls, can these four contracts get the value from this contract somehow? 
        wheelContract.setOffset(offset);
        engineContract.setOffset(offset);
        buildContract.setOffset(offset);
        wrappingContract.setOffset(offset);
    }

    // Talk to the guys about this, might want to limit our ability to pull out all at once for public trust
    function withdraw(uint256 _amount) onlyOwner public {
        uint balance = address(this).balance;
        require(_amount <= balance, "Withdraw amount exceeds contract balance");
        payable(owner()).transfer(_amount);
    }

}