// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SimpleToken} from "src/SimpleToken.sol";
import {SimpleAggregator} from "src/SimpleAggregator.sol";
import {MessageEndpoint} from "src/SimpleAggregator.sol";
contract SimpleRegistry is Ownable {
    SimpleToken public token;
    SimpleAggregator public aggregator;
    struct TokenMessage {
        address receiver;
        uint256 amount;
        bool isMint;
    }
    struct tokenEvent {
        address receiver;
        uint256 amount;
        uint destinationid; // destinationid 0 encodes local.
        uint256 timestamp;
        bool isMint;
    }
    // keep track of destination address
    mapping(uint => string) public ChainDestinationAddress;
    mapping(uint => string) public ChainIdMapping;
    // keep track of minting and burning

    // message will be in this format {address, uint, bool} => {receiver, amount, isMint}
    constructor(address payable _aggregator) Ownable(msg.sender) {
        token = new SimpleToken(); // Registry is the owner;
        aggregator = SimpleAggregator(_aggregator);
    }


    function setDestinationAddress(uint chain, string calldata _address) public onlyOwner {
        ChainDestinationAddress[chain] = _address;
    }
    function setChainIdMapping(uint chainId, string calldata chain) public onlyOwner {
        ChainIdMapping[chainId] = chain;
    }

    function setAggregator(address payable _aggregator) public onlyOwner {
        aggregator = SimpleAggregator(_aggregator);
    }

    function mint(address to, uint256 amount) public {
        token.mint(to, amount);
    }
    function burn(address from, uint256 amount) public {

        token.burn(from, amount);
    }

    function validateMessage(bytes32 messageId) public view returns (bool verified, bytes memory finalPayload) {
        return aggregator.aggregateMultipleMessages(messageId);
    }

    /**
     * @dev Send a message to multiple chains
     * @param destinationId the id of the destination chain
     * @param receiver_address the address of the receiver
     * @param payload the payload to be sent
     */
    function  sendMultipleMessages(uint destinationId, address receiver_address, bytes calldata payload) public payable onlyOwner{
        // arbitrary payload
        aggregator.sendMultipleMessages{value:msg.value}(ChainIdMapping[destinationId], ChainDestinationAddress[destinationId], payload);
    }

    /**
     * @dev Mint tokens on a remote chain
     * @param destinationId the id of the destination chain
     * @param receiver_address the address of the receiver
     */
    function mintRemote(uint destinationId, address receiver_address, uint amount) public onlyOwner {
        TokenMessage memory message = TokenMessage(receiver_address, amount, true);
        bytes memory payload = abi.encode(message);
        aggregator.sendMultipleMessages(ChainIdMapping[destinationId], ChainDestinationAddress[destinationId], payload);
    }

    /**
     * @dev Burn tokens on a remote chain
     * @param destinationId the id of the destination chain
     * @param receiver_address the address of the receiver
     */
    function burnRemote(uint destinationId, address receiver_address, uint amount) public onlyOwner{
        TokenMessage memory message = TokenMessage(receiver_address, amount, false);
        bytes memory payload = abi.encode(message);
        aggregator.sendMultipleMessages(ChainIdMapping[destinationId], ChainDestinationAddress[destinationId], payload);
    }

    /**
     * @dev Receive a message from a remote chain and execute the message
     * @param messageId the id of the message
     */
    function receiveRemoteMessage(bytes32 messageId) public {
        (bool verified, bytes memory finalPayload) = validateMessage(messageId);
        TokenMessage memory message = abi.decode(finalPayload, (TokenMessage));
        if (message.isMint) {
            token.mint(message.receiver, message.amount);
        } else {
            token.burn(message.receiver, message.amount);
        }
    }

    function addEndpoint(MessageEndpoint _endpoint) public onlyOwner {
        aggregator.addEndpoint(_endpoint);
    }

    function removeEndpoint(MessageEndpoint _endpoint) public onlyOwner {
        aggregator.removeEndpoint(_endpoint);
    }

    function setThreshold(uint _threshold) public onlyOwner {
        aggregator.setThreshold(_threshold);
    }
    receive () external payable {}

}