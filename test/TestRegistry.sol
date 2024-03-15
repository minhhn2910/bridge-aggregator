// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";



import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {MockRouterChainlink} from "src/bridge-adapter/chainlink/MockRouter.sol";
import {ChainlinkMessageEndpoint} from "src/bridge-adapter/chainlink/ChainlinkMessageEndpoint.sol";

import {MockToken} from "src/utils/MockToken.sol";


import {MockEndpointLayerZero} from "src/bridge-adapter/layerzero/MockEndpoint.sol";
import {LayerZeroMessageEndpoint} from "src/bridge-adapter/layerzero/LayerZeroMessageEndpoint.sol";

import {MockGasServiceAxelar} from "src/bridge-adapter/axelar/MockGasService.sol";
import {MockGatewayAxelar} from "src/bridge-adapter/axelar/MockGateway.sol";
import {AxelarMessageEndpoint} from "src/bridge-adapter/axelar/AxelarMessageEndpoint.sol";


import {MockRelayerWormhole} from "src/bridge-adapter/wormhole/MockRelayer.sol";
import {WormholeMessageEndpoint} from "src/bridge-adapter/wormhole/WormholeMessageEndpoint.sol";

import {Origin, ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import {SimpleAggregator} from "src/SimpleAggregator.sol";
import {SimpleRegistry} from "src/SimpleRegistry.sol";
import {SimpleToken} from "src/SimpleToken.sol";
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
    struct TokenMessage {
        address receiver;
        uint256 amount;
        bool isMint;
    }
    function testAggregator() public {
        address mock_gas_service_chain1;
        address mock_gateway_chain1;
        address mock_gas_service_chain2;
        address mock_gateway_chain2;
        address mock_sender = 0x3333333333333333333333333333333333333333;

        bool verified; bytes memory finalPayload;
        TokenMessage memory tokenMessage = TokenMessage({
            receiver: address(0x1111111111111111111111111111111111111111),
            amount: 100,
            isMint: true
        });
        // bytes memory my_payload = abi.encodePacked(uint(1234), "hello im sender test");
        bytes memory my_payload = abi.encode(tokenMessage);
        bytes32 messageId = keccak256(my_payload);

        vm.selectFork(mainnetFork_1);
        mock_gas_service_chain1 = address(new MockGasServiceAxelar());
        mock_gateway_chain1 = address(new MockGatewayAxelar());
        AxelarMessageEndpoint axelar_sender = new AxelarMessageEndpoint(mock_gateway_chain1, mock_gas_service_chain1);
        vm.selectFork(mainnetFork_2);
        mock_gas_service_chain2 = address(new MockGasServiceAxelar());
        mock_gateway_chain2 = address(new MockGatewayAxelar());
        AxelarMessageEndpoint axelar_receiver = new AxelarMessageEndpoint(mock_gateway_chain2, mock_gas_service_chain2);

        // Chainlink
        // setup
        vm.selectFork(mainnetFork_1);
        MockRouterChainlink mock_router_chain1 = new MockRouterChainlink();

        ChainlinkMessageEndpoint chainlink_sender = new ChainlinkMessageEndpoint(address(mock_router_chain1));
        chainlink_sender.setAddressMapping("0x1234", mock_sender);
        chainlink_sender.setChainMapping("chain1", 1);
        chainlink_sender.setChainMapping("chain2", 2);

        vm.selectFork(mainnetFork_2);
        MockRouterChainlink mock_router_chain2 = new MockRouterChainlink();
        ChainlinkMessageEndpoint chainlink_receiver = new ChainlinkMessageEndpoint(address(mock_router_chain2));
        chainlink_receiver.setAddressMapping("0x1234", mock_sender);
        chainlink_receiver.setChainMapping("chain1", 1);
        chainlink_receiver.setChainMapping("chain2", 2);

        // LayzerZero
        vm.selectFork(mainnetFork_1);
        address endpoint_chain1 = address(new MockEndpointLayerZero());
        LayerZeroMessageEndpoint layerzero_sender = new LayerZeroMessageEndpoint(endpoint_chain1);
        layerzero_sender.setPeer(1, bytes32(uint256(uint160(mock_sender)) << 96));
        console.logString("print peer sender");
        bytes32 sender_peer = layerzero_sender.peers(1);
        layerzero_sender.setEidMapping("chain2", 1);
        console.logBytes32(sender_peer);

        vm.selectFork(mainnetFork_2);
        address endpoint_chain2 = address(new MockEndpointLayerZero());
        LayerZeroMessageEndpoint layerzero_receiver = new LayerZeroMessageEndpoint(endpoint_chain2);

        // // set peer
        layerzero_receiver.setPeer(1, bytes32(uint256(uint160(mock_sender)) << 96));
        layerzero_receiver.setEidMapping("chain2", 1);
        console.logString("print peer receiver");
        bytes32 recv_peer = layerzero_receiver.peers(1);
        console.logBytes32(recv_peer);

        vm.selectFork(mainnetFork_1);
        address [] memory senders = new address[](3);
        senders[0] = address(axelar_sender);
        senders[1] = address(chainlink_sender);
        senders[2] = address(layerzero_sender);
        SimpleAggregator my_sender_aggregator = new SimpleAggregator(senders);
        my_sender_aggregator.sendMultipleMessages("chain2", "0x1234", my_payload);
        vm.selectFork(mainnetFork_2);
        address [] memory receivers = new address[](3);
        receivers[0] = address(axelar_receiver);
        receivers[1] = address(chainlink_receiver);
        receivers[2] = address(layerzero_receiver);

        SimpleAggregator my_receiver_aggregator = new SimpleAggregator(receivers);

        SimpleRegistry my_receiver_registry = new SimpleRegistry(address(my_receiver_aggregator));
        // may need to set owner or create aggregator inside constructor


        // receive a message Axelar
        vm.selectFork(mainnetFork_2);
        axelar_receiver.execute(bytes32(hex"0123"),"chain1", "0x1234", my_payload);


        (verified, finalPayload) = my_receiver_aggregator.aggregateMultipleMessages(messageId);
        console.logBool(verified);
        console.logBytes(finalPayload);
        // expect not verified
        assertEq(verified, false);


        // receive a message Chainlink
        vm.selectFork(mainnetFork_2);
        // simulating oracle submitting message
        uint64 destinationChainSelector = chainlink_receiver.chainMapping("chain2");
        address destinationReceiver = chainlink_receiver.addressMapping("0x1234");
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: 1,
            sender: abi.encode(mock_sender),
            data: my_payload,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        vm.deal(address(mock_router_chain2),10**18);
        vm.prank(address(mock_router_chain2));
        chainlink_receiver.ccipReceive(message);

        (verified, finalPayload) = my_receiver_aggregator.aggregateMultipleMessages(messageId);
        console.logBool(verified);
        console.logBytes(finalPayload);
        // expect verified
        assertEq(verified, true);
        // expect message
        assertEq(abi.encode(finalPayload), abi.encode(my_payload));


        // receive a message LayerZero
        vm.selectFork(mainnetFork_2);
        vm.deal(endpoint_chain2,10**18);
        vm.prank(endpoint_chain2);
        Origin memory origin = Origin({
            srcEid: 1,
            sender: bytes32(uint256(uint160(mock_sender)) << 96),
            nonce: 0
        });
        layerzero_receiver.lzReceive(origin, bytes32(hex"1234"), my_payload, mock_sender, bytes(hex"00"));


        (verified, finalPayload) = my_receiver_aggregator.aggregateMultipleMessages(messageId);
        console.logBool(verified);
        console.logBytes(finalPayload);
        // expect verified
        assertEq(verified, true);
        // expect message
        assertEq(abi.encode(finalPayload), abi.encode(my_payload));

        my_receiver_registry.receiveRemoteMessage(messageId);

        SimpleToken token = my_receiver_registry.token();
        assertEq(token.balanceOf(address(0x1111111111111111111111111111111111111111)), 100);
    }
}
