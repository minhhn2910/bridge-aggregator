// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";


import {ChainlinkReceiver} from "src/bridge-adapter/chainlink/Receiver.sol";
import {ChainlinkSender} from "src/bridge-adapter/chainlink/Sender.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {MockRouterChainlink} from "src/bridge-adapter/chainlink/MockRouter.sol";

import {MockToken} from "src/utils/MockToken.sol";

import {LayerZeroReceiver} from "src/bridge-adapter/layerzero/Receiver.sol";
import {LayerZeroSender} from "src/bridge-adapter/layerzero/Sender.sol";
import {MockEndpointLayerZero} from "src/bridge-adapter/layerzero/MockEndpoint.sol";

import {MockGasServiceAxelar} from "src/bridge-adapter/axelar/MockGasService.sol";
import {MockGatewayAxelar} from "src/bridge-adapter/axelar/MockGateway.sol";
import {AxelarSender} from "src/bridge-adapter/axelar/Sender.sol";
import {AxelarReceiver} from "src/bridge-adapter/axelar/Receiver.sol";

import {WormholeReceiver} from "src/bridge-adapter/wormhole/Receiver.sol";
import {WormholeSender} from "src/bridge-adapter/wormhole/Sender.sol";
import {MockRelayerWormhole} from "src/bridge-adapter/wormhole/MockRelayer.sol";

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
        ChainlinkSender sender = new ChainlinkSender(address(mock_router_chain1),mock_link);
        vm.selectFork(mainnetFork_2);
        MockRouterChainlink mock_router_chain2 = new MockRouterChainlink();
        ChainlinkReceiver receiver = new ChainlinkReceiver(address(mock_router_chain2));
        // send a message
        vm.selectFork(mainnetFork_1);
        // function send(
        //         uint64 destinationChainSelector,
        //         address receiver,
        //         string memory messageText,
        //         PayFeesIn payFeesIn
        //         )
        bytes32 messageid = sender.send(1, address(receiver), "hello im sender", ChainlinkSender.PayFeesIn.Native);
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
    function testAxelar() public {
        address mock_sender = 0x3333333333333333333333333333333333333333;
        address mock_gas_service_chain1;
        address mock_gateway_chain1;
        address mock_gas_service_chain2;
        address mock_gateway_chain2;

        vm.selectFork(mainnetFork_1);
        mock_gas_service_chain1 = address(new MockGasServiceAxelar());
        mock_gateway_chain1 = address(new MockGatewayAxelar());
        AxelarSender sender = new AxelarSender(mock_gateway_chain1, mock_gas_service_chain1);
        vm.selectFork(mainnetFork_2);
        mock_gas_service_chain2 = address(new MockGasServiceAxelar());
        mock_gateway_chain2 = address(new MockGatewayAxelar());
        AxelarReceiver receiver = new AxelarReceiver(mock_gateway_chain2, mock_gas_service_chain2);
        //         string calldata destinationChain,
        // string calldata destinationAddress,
        // string calldata value_
        // send a message
        vm.selectFork(mainnetFork_1);
        sender.send{value:1}("chain2", "0x1234", "hello im sender");
        // receive a message
        vm.selectFork(mainnetFork_2);
        // bytes32 commandId,
        // string calldata sourceChain,
        // string calldata sourceAddress,
        // bytes calldata payload
        receiver.execute(bytes32(hex"0123"),"chain1", "0x1234", abi.encode("hello im sender"));

        // // expect message
        string memory message = receiver.value();
        assertEq(abi.encode(message), abi.encode("hello im sender"));

    }
    function testWormhole () public {
        address mock_sender = 0x3333333333333333333333333333333333333333;
        address mock_relayer_chain1;
        address mock_relayer_chain2;
        vm.selectFork(mainnetFork_1);
        mock_relayer_chain1 = address(new MockRelayerWormhole());
        WormholeSender sender = new WormholeSender(mock_relayer_chain1);
        vm.selectFork(mainnetFork_2);
        mock_relayer_chain2 = address(new MockRelayerWormhole());
        WormholeReceiver receiver = new WormholeReceiver(mock_relayer_chain2);
        // send a message
        vm.selectFork(mainnetFork_1);
        sender.sendMessage(1, mock_sender, "hello im sender");
        // receive a message
        vm.selectFork(mainnetFork_2);
        vm.deal(mock_relayer_chain2,10**18);
        vm.prank(mock_relayer_chain2);
        receiver.receiveWormholeMessages(abi.encode("hello im sender",mock_sender), new bytes[](0), bytes32(0), 1, bytes32(0));
        // expect message
        string memory message = receiver.latestGreeting();
        assertEq(abi.encode(message), abi.encode("hello im sender"));


    }
}
