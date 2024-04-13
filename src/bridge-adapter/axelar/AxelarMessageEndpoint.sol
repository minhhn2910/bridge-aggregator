pragma solidity ^0.8.0;
import "../MessageEndpoint.sol";
import "./Sender.sol";
import "./Receiver.sol";
contract AxelarMessageEndpoint is MessageEndpoint, AxelarExecutable{

    IAxelarGasService public immutable gasService;
    // to call bridge adapter
    function sendMessage(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload
    ) external payable override returns (bytes32) {
        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            msg.sender
        );
        gateway.callContract(destinationChain, destinationAddress, payload);
        bytes32 messageId = keccak256(payload);
        sentMessages[messageId] = payload;
    }

    // to be called by the bridge adapter to get message data
    function deliverMessage(bytes32 messageId) external view override returns(bytes memory) {
        bytes memory payload = receivedMessages[messageId];
        return payload;
    }
    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
    }

    // Handles calls created by setAndSend. Updates this contract's value
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        bytes32 messageId = keccak256(payload_);
        receivedMessages[messageId] = payload_;
    }
    receive () external payable {}
}
