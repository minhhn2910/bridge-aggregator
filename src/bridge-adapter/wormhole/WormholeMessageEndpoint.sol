// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MessageEndpoint } from "src/bridge-adapter/MessageEndpoint.sol";
contract WormholeMessageEndpoint is IWormholeReceiver, MessageEndpoint, Ownable{

    event GreetingReceived(string greeting, uint16 senderChain, address sender);

    uint256 constant GAS_LIMIT = 50_000;

    IWormholeRelayer public immutable wormholeRelayer;
    mapping (string => uint16) public targetChainMapping;
    mapping (string => address) public addressMapping;

    constructor(address _wormholeRelayer) Ownable(msg.sender) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    function setTargetChainMapping(string calldata chain, uint16 targetChain) external onlyOwner {
        targetChainMapping[chain] = targetChain;
    }
    function setAddressMapping(string calldata address_, address targetAddress) external onlyOwner {
        addressMapping[address_] = targetAddress;
    }

    function quoteCost(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }
   function sendMessage(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload
    ) external payable override returns (bytes32) {
        uint16 targetChain = targetChainMapping[destinationChain];
        address targetAddress = addressMapping[destinationAddress];

        uint256 cost = quoteCost(targetChain);
        require(msg.value >= cost);
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            payload, // payload
            0, // no receiver value needed since we're just passing a message
            GAS_LIMIT
        );
        bytes32 messageId = keccak256(payload);
        sentMessages[messageId] = payload;
        return messageId;
    }
    function deliverMessage(bytes32 messageId) external view override returns(bytes memory) {
        bytes memory payload = receivedMessages[messageId];
        return payload;
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32, // address that called 'sendPayloadToEvm' (HelloWormhole contract address)
        uint16 sourceChain,
        bytes32 // unique identifier of delivery
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");

        bytes32 messageId = keccak256(payload);
        receivedMessages[messageId] = payload;
    }
}