// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Counter} from "src/Counter.sol";
import {ChainlinkMessageReceiver} from "src/bridge-adapter/chainlink/Receiver.sol";
import {ChainlinkMessageSender} from "src/bridge-adapter/chainlink/Sender.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {MockRouterChainlink} from "src/bridge-adapter/chainlink/MockRouter.sol";
import {MockToken} from "src/utils/MockToken.sol";
import {LayerZeroReceiver} from "src/bridge-adapter/layerzero/Receiver.sol";
import {LayerZeroSender} from "src/bridge-adapter/layerzero/Sender.sol";
import {MockEndpointLayerZero} from "src/bridge-adapter/layerzero/MockEndpoint.sol";
import {Origin, ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
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
        Counter simple = new Counter();

        // and can be used as normal
        simple.setNumber(100);
        assertEq(simple.number(), 100);

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
    /*
        struct Any2EVMMessage {
            bytes32 messageId; // MessageId corresponding to ccipSend on source.
            uint64 sourceChainSelector; // Source chain selector.
            bytes sender; // abi.decode(sender) if coming from an EVM chain.
            bytes data; // payload sent in original message.
            EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
        }
     */
    function testChainlinkCCIP() public{

        address mock_sender = 0x3333333333333333333333333333333333333333;
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: 1,
            sender: abi.encode(mock_sender),
            data: abi.encode("hello im sender"),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        // setup
        vm.selectFork(mainnetFork_1);
        MockRouterChainlink mock_router_chain1 = new MockRouterChainlink();
        MockToken mock_token = new MockToken();
        address mock_link = address(mock_token);
        ChainlinkMessageSender sender = new ChainlinkMessageSender(address(mock_router_chain1),mock_link);
        vm.selectFork(mainnetFork_2);
        MockRouterChainlink mock_router_chain2 = new MockRouterChainlink();
        ChainlinkMessageReceiver receiver = new ChainlinkMessageReceiver(address(mock_router_chain2));
        // send a message
        vm.selectFork(mainnetFork_1);
        // function send(
        //         uint64 destinationChainSelector,
        //         address receiver,
        //         string memory messageText,
        //         PayFeesIn payFeesIn
        //         )
        bytes32 messageid = sender.send(1, address(receiver), "hello im sender", ChainlinkMessageSender.PayFeesIn.Native);
        console.logBytes32(messageid);
        // receive a message
        vm.selectFork(mainnetFork_2);
        vm.deal(address(mock_router_chain2),10**18);
        vm.prank(address(mock_router_chain2));
        receiver.ccipReceive(message);
        // expect message
        (bytes32 latestMessageId, uint64 latestSourceChainSelector, address latestSender, string memory latestMessage) = receiver.getLatestMessageDetails();
        assertEq(abi.encode(latestMessage), abi.encode("hello im sender"));
    }

    function testLayerZero() public {
        address mock_sender = 0x3333333333333333333333333333333333333333;
        vm.selectFork(mainnetFork_1);
        address endpoint_chain1 = address(new MockEndpointLayerZero());
        LayerZeroSender sender = new LayerZeroSender(endpoint_chain1, mock_sender);

        vm.selectFork(mainnetFork_2);
        address endpoint_chain2 = address(new MockEndpointLayerZero());
        LayerZeroReceiver receiver = new LayerZeroReceiver(endpoint_chain2, mock_sender);

        // send a message
        vm.selectFork(mainnetFork_1);
        sender.setPeer(1, bytes32(uint256(uint160(mock_sender)) << 96));
        console.logString("print peer sender");
        bytes32 sender_peer = sender.peers(1);
        console.logBytes32(sender_peer);
        sender.send(1, "hello im sender", bytes(hex"1234"));
        // // receive a message
        vm.selectFork(mainnetFork_2);
        // // set peer
        receiver.setPeer(1, bytes32(uint256(uint160(mock_sender)) << 96));
        console.logString("print peer receiver");
        bytes32 recv_peer = receiver.peers(1);
        console.logBytes32(recv_peer);

        vm.deal(endpoint_chain2,10**18);
        vm.prank(endpoint_chain2);

        Origin memory origin = Origin({
            srcEid: 1,
            sender: bytes32(uint256(uint160(mock_sender)) << 96),
            nonce: 0
        });
        receiver.lzReceive(origin, bytes32(hex"1234"), abi.encode("hello im sender"), mock_sender, bytes(hex"00"));

        // // expect message
        string memory message = receiver.data();
        assertEq(abi.encode(message), abi.encode("hello im sender"));

    }
}
contract SimpleCrossChainContract {
    uint256 public value;

    event ValueSet(uint256 value, uint256 chain_id, address destination);
    event msgSent(uint256 _value, uint chain_id, address destination);

    function sendMsg(uint256 _value, uint chain_id, address destination) public {
        emit msgSent(_value, chain_id, destination);
    }

    function receiveMsg(uint256 _value, uint chain_id, address destination) public {
        value = _value;
        emit ValueSet(_value, chain_id, destination);
    }

}
