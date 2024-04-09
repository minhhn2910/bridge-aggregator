// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { OAppSender, MessagingFee } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { OAppReceiver, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol";
import { OAppCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol";
import {IOAppCore} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MessageEndpoint } from "src/bridge-adapter/MessageEndpoint.sol";

/**
 * @notice THIS IS AN EXAMPLE CONTRACT. DO NOT USE THIS CODE IN PRODUCTION.
 */

contract LayerZeroMessageEndpoint is MessageEndpoint, OAppCore, OAppSender, OAppReceiver{
    bytes myOption = hex'0003010011010000000000000000000000000000ea60';

    mapping (string => uint32) public EidMapping;
    constructor(address _endpoint) OAppCore(_endpoint, msg.sender) Ownable(msg.sender) {
    }

    function oAppVersion() public view override(IOAppCore, OAppReceiver, OAppSender) returns (uint64 senderVersion, uint64 receiverVersion) {
        return (1, 1);
    }
    function setEidMapping(string calldata chain, uint32 eid) external onlyOwner {
        EidMapping[chain] = eid;
    }
    function setMyOption(bytes calldata option) external onlyOwner {
        myOption = option;
    }

    function sendMessage(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload
    ) external payable override returns (bytes32) {
        uint32 _dstEid = EidMapping[destinationChain];
        // bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        // mysender.send(_dstEid, payload, myOption);
        _lzSend(
            _dstEid,
            payload,
            myOption,
            // Fee in native gas and ZRO token.
            MessagingFee(msg.value, 0),
            // Refund address in case of failed source message.
            payable(msg.sender)
        );
        bytes32 messageId = keccak256(payload);
        sentMessages[messageId] = payload;
        return messageId;
    }

    function deliverMessage(bytes32 messageId) external view override returns(bytes memory) {
        bytes memory payload = receivedMessages[messageId];
        return payload;
    }

    /* @dev Quotes the gas needed to pay for the full omnichain transaction.
    * @return nativeFee Estimated gas fee in native gas.
    * @return lzTokenFee Estimated gas fee in ZRO token.
    */
    function quote(
        uint32 _dstEid, // Destination chain's endpoint ID.
        bytes memory _payload, // The message to send.
        bytes calldata _options
    ) public view returns (uint256 nativeFee, uint256 lzTokenFee) {
        MessagingFee memory fee = _quote(_dstEid, _payload, _options, false);
        return (fee.nativeFee, fee.lzTokenFee);
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address,  // Executor address as specified by the OApp.
        bytes calldata  // Any extra data or options to trigger on receipt.
    ) internal override {
        bytes32 application_id = keccak256(payload);
        receivedMessages[application_id] = payload;
    }
    receive () external payable {}
}