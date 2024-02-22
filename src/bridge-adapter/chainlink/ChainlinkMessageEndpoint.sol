// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {MessageEndpoint} from "src/bridge-adapter/MessageEndpoint.sol";
/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract ChainlinkMessageEndpoint is CCIPReceiver, MessageEndpoint, Ownable {
    mapping (string => uint64) public chainMapping;
    mapping (string => address) public addressMapping;
    mapping (bytes32 => bytes32) public messageIdMapping;
    enum PayFeesIn {
        Native,
        LINK
    }


    event MessageSent(bytes32 messageId);

    constructor(address router)  CCIPReceiver(router)  Ownable(msg.sender) {
        i_router = router;

    }
    function setChainMapping(string calldata chain, uint64 chainSelector) external onlyOwner {
        chainMapping[chain] = chainSelector;
    }
    function setAddressMapping(string calldata address_, address addressSelector) external onlyOwner {
        addressMapping[address_] = addressSelector;
    }
    function sendMessage(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload
    ) external payable override returns (bytes32) {
        uint64 destinationChainSelector = chainMapping[destinationChain];
        address receiver = addressMapping[destinationAddress];

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: payload,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });
        bytes32 messageId;
        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );
        messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );

/* simplify logic only support native
        if (payFeesIn == PayFeesIn.LINK) {
            IERC20(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }
*/
        bytes32 application_id = keccak256(payload);
        messageIdMapping[application_id] = messageId;
        sentMessages[application_id] = payload;
        return application_id;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        bytes32 latestMessageId = message.messageId;
        uint64 latestSourceChainSelector = message.sourceChainSelector;
        address latestSender = abi.decode(message.sender, (address));
        bytes memory payload = message.data;
        bytes32 application_id = keccak256(payload);
        receivedMessages[application_id] = payload;
    }

    function deliverMessage(bytes32 messageId) external view override returns(bytes memory) {
        bytes memory payload = receivedMessages[messageId];
        return payload;
    }
}