// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
contract MockRouter is IRouterClient {
    function ccipSend(uint64 destinationChainSelector, Client.EVM2AnyMessage calldata message) external payable returns (bytes32) {
        return bytes32(hex"1234");
    }
    function getFee(uint64 destinationChainSelector, Client.EVM2AnyMessage memory message) external view returns (uint256 fee){
        return 0;
    }

    function isChainSupported(uint64 chainSelector) external view returns (bool supported){
        return true;
    }

    function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens){
        return new address[](0);
    }

}