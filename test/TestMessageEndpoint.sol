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

    function testAxelarMessageEndpoint() public {
        address mock_gas_service_chain1;
        address mock_gateway_chain1;
        address mock_gas_service_chain2;
        address mock_gateway_chain2;

        vm.selectFork(mainnetFork_1);
        bytes memory my_payload = abi.encodePacked(uint(1234), "hello im sender");
        bytes32 messageId = keccak256(my_payload);
        mock_gas_service_chain1 = address(new MockGasServiceAxelar());
        mock_gateway_chain1 = address(new MockGatewayAxelar());
        AxelarMessageEndpoint sender = new AxelarMessageEndpoint(mock_gateway_chain1, mock_gas_service_chain1);
        vm.selectFork(mainnetFork_2);
        mock_gas_service_chain2 = address(new MockGasServiceAxelar());
        mock_gateway_chain2 = address(new MockGatewayAxelar());
        AxelarMessageEndpoint receiver = new AxelarMessageEndpoint(mock_gateway_chain2, mock_gas_service_chain2);
        // string calldata destinationChain,
        // string calldata destinationAddress,
        // string calldata value_
        // send a message

        vm.selectFork(mainnetFork_1);
        sender.sendMessage{value:1}("chain2", "0x1234", my_payload);
        // receive a message
        vm.selectFork(mainnetFork_2);

        receiver.execute(bytes32(hex"0123"),"chain1", "0x1234", my_payload);

        bytes memory new_payload = receiver.deliverMessage(messageId);
        // expect message
        assertEq(abi.encode(new_payload), abi.encode(my_payload));
    }

    function testChainlinkMessageEndpoint() public{

        address mock_sender = 0x3333333333333333333333333333333333333333;
        bytes memory my_payload = abi.encodePacked(uint(1234), "hello im sender");
        bytes32 messageId = keccak256(my_payload);
        // setup
        vm.selectFork(mainnetFork_1);
        MockRouterChainlink mock_router_chain1 = new MockRouterChainlink();

        ChainlinkMessageEndpoint sender = new ChainlinkMessageEndpoint(address(mock_router_chain1));
        sender.setAddressMapping("0x1234", mock_sender);
        sender.setChainMapping("chain1", 1);
        sender.setChainMapping("chain2", 2);

        vm.selectFork(mainnetFork_2);
        MockRouterChainlink mock_router_chain2 = new MockRouterChainlink();
        ChainlinkMessageEndpoint receiver = new ChainlinkMessageEndpoint(address(mock_router_chain2));
        receiver.setAddressMapping("0x1234", mock_sender);
        receiver.setChainMapping("chain1", 1);
        receiver.setChainMapping("chain2", 2);
        // send a message
        vm.selectFork(mainnetFork_1);
        bytes32 messageid = sender.sendMessage{value:1}("chain2", "0x1234", my_payload);

        // receive a message
        vm.selectFork(mainnetFork_2);
        // simulating oracle submitting message
        uint64 destinationChainSelector = receiver.chainMapping("chain2");
        address destinationReceiver = receiver.addressMapping("0x1234");
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: 1,
            sender: abi.encode(mock_sender),
            data: my_payload,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        vm.deal(address(mock_router_chain2),10**18);
        vm.prank(address(mock_router_chain2));


        receiver.ccipReceive(message);

        bytes memory new_payload = receiver.deliverMessage(messageId);
        console.logBytes(my_payload);
        console.logBytes(new_payload);

        // expect message
        assertEq(abi.encode(new_payload), abi.encode(my_payload));
    }


    function testLayerZero() public {
        address mock_sender = 0x3333333333333333333333333333333333333333;
        bytes memory my_payload = abi.encodePacked(uint(1234), "hello im sender");
        bytes32 messageId = keccak256(my_payload);

        vm.selectFork(mainnetFork_1);
        address endpoint_chain1 = address(new MockEndpointLayerZero());
        LayerZeroMessageEndpoint sender = new LayerZeroMessageEndpoint(endpoint_chain1);

        vm.selectFork(mainnetFork_2);
        address endpoint_chain2 = address(new MockEndpointLayerZero());
        LayerZeroMessageEndpoint receiver = new LayerZeroMessageEndpoint(endpoint_chain2);

        // send a message
        vm.selectFork(mainnetFork_1);
        sender.setPeer(1, bytes32(uint256(uint160(mock_sender)) << 96));
        console.logString("print peer sender");
        bytes32 sender_peer = sender.peers(1);
        sender.setEidMapping("chain2", 1);
        console.logBytes32(sender_peer);
        bytes32 messageid = sender.sendMessage{value:1}("chain2", "0x1234", my_payload);
        // // receive a message
        vm.selectFork(mainnetFork_2);
        // // set peer
        receiver.setPeer(1, bytes32(uint256(uint160(mock_sender)) << 96));
        receiver.setEidMapping("chain2", 1);
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
        receiver.lzReceive(origin, bytes32(hex"1234"), my_payload, mock_sender, bytes(hex"00"));

        bytes memory new_payload = receiver.deliverMessage(messageId);
        console.logBytes(my_payload);
        console.logBytes(new_payload);

        // expect message
        assertEq(abi.encode(new_payload), abi.encode(my_payload));

    }
/*
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
    */
}
