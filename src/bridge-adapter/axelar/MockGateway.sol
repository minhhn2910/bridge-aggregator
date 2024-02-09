pragma solidity ^0.8.0;

import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';

contract MockGatewayAxelar is IAxelarGateway {

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external {}

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external {}

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external {}

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool) {
        return true;
    }

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool) {
        return true;
    }

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool) {
        return true;
    }

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool) {
        return true;
    }

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address) {
        return address(0);
    }

    function tokenDeployer() external view returns (address) {
        return address(0);
    }

    function tokenMintLimit(string memory symbol) external view returns (uint256) {
        return 0;
    }

    function tokenMintAmount(string memory symbol) external view returns (uint256) {
        return 0;
    }

    function allTokensFrozen() external view returns (bool) {
        return false;
    }

    function implementation() external view returns (address) {
        return address(0);
    }

    function tokenAddresses(string memory symbol) external view returns (address) {
        return address(0);
    }

    function tokenFrozen(string memory symbol) external view returns (bool) {
        return false;
    }

    function isCommandExecuted(bytes32 commandId) external view returns (bool) {
        return false;
    }

    /************************\
    |* Governance Functions *|
    \************************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external {}

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external {}

    /**********************\
    |* External Functions *|
    \**********************/

    function execute(bytes calldata input) external {}

   function governance() external view returns (address) {
        return address(0);
    }

    function mintLimiter() external view returns (address) {
        return address(0);
    }


    function transferGovernance(address newGovernance) external {}
    function transferMintLimiter(address newGovernance) external {}

    function setup(bytes calldata data) external {}

    function contractId() external pure returns (bytes32) {
        return bytes32(hex"0123");
    }

}

