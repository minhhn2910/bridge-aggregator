pragma solidity ^0.8.0;

abstract contract MessageEndpoint {
    mapping(bytes32 => bytes) public receivedMessages;
    mapping(bytes32 => bytes) public sentMessages;
    // to call bridge adapter
    function sendMessage(
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload
    ) external payable virtual returns (bytes32 messageId) {}

    // to be called by the bridge adapter
    function deliverMessage(bytes32) external view virtual returns(bytes memory) {}
}
