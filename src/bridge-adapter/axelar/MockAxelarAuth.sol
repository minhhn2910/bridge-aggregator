pragma solidity ^0.8.0;
contract MockAxelarAuth  {
    function validateProof(bytes32 messageHash, bytes calldata proof) external returns (bool currentOperators){
        return true;
    }

    function transferOperatorship(bytes calldata params) external{}
}