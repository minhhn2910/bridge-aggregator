// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract ForkTest is Test {
    // the identifiers of the forks
    uint256 mainnetFork_1;
    uint256 mainnetFork_2;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need
    //inside your .env file e.g:
    string MAINNET_RPC_URL = 'https://eth.llamarpc.com';
    //string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    //string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");

    // create two _different_ forks during setup
    function setUp() public {
        mainnetFork_1 = vm.createFork(MAINNET_RPC_URL, 19_000_000);
        mainnetFork_2 = vm.createFork(MAINNET_RPC_URL, 19_000_000);
    }

    // demonstrate fork ids are unique
    function testForkIdDiffer() public {
        assert(mainnetFork_1 != mainnetFork_2);
    }

    // select a specific fork
    function testCanSelectFork() public {
        // select the fork
        vm.selectFork(mainnetFork_1);
        assertEq(vm.activeFork(), mainnetFork_1);

        // from here on data is fetched from the `mainnetFork` if the EVM requests it and written to the storage of `mainnetFork`
    }

    // manage multiple forks in the same test
    function testCanSwitchForks() public {
        vm.selectFork(mainnetFork_1);
        assertEq(vm.activeFork(), mainnetFork_1);

        vm.selectFork(mainnetFork_2);
        assertEq(vm.activeFork(), mainnetFork_2);
    }

    // forks can be created at all times
    function testCanCreateAndSelectForkInOneStep() public {
        // creates a new fork and also selects it
        uint256 anotherFork = vm.createSelectFork(MAINNET_RPC_URL);
        assertEq(vm.activeFork(), anotherFork);
    }

    // set `block.number` of a fork
    function testCanSetForkBlockNumber() public {
        vm.selectFork(mainnetFork_2);
        vm.rollFork(1_337_000);
        assertEq(block.number, 1_337_000);
    }
     function testCreateContract() public {
        vm.selectFork(mainnetFork_1);
        assertEq(vm.activeFork(), mainnetFork_1);

        // the new contract is written to `mainnetFork`'s storage
        SimpleStorageContract simple = new SimpleStorageContract();

        // and can be used as normal
        simple.set(100);
        assertEq(simple.value(), 100);

        // after switching to another contract we still know `address(simple)` but the contract only lives in `mainnetFork`
        vm.selectFork(mainnetFork_2);

        /* this call will therefore revert because `simple` now points to a contract that does not exist on the active fork
        * it will produce following revert message:
        *
        * "Contract 0xCe71065D4017F316EC606Fe4422e11eB2c47c246 does not exist on active fork with id `1`
        *       But exists on non active forks: `[0]`"
        */
        // simple.value();
    }
}
contract SimpleCrossChainContract {
    uint256 public value;

    event ValueSet(uint256 value, uint256 chain_id, address destination);
    event sendMsg(uint256 _value, uint chain_id, address destination);

    function sendMsg(uint256 _value, uint chain_id, address destination) public {
        emit sendMsg(_value, chain_id, destination);
    }

    function receiveMsg(uint256 _value, uint chain_id, address destination) public {
        value = _value;
        emit ValueSet(_value, chain_id, destination);
    }

}
