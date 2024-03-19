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

contract ForkTest is Test {
    struct LayerzeroEndpoint{
        address endpoint;
        uint32 endpointId;
    }
    mapping (string => LayerzeroEndpoint) layerzero_endpoints;
    // bytes layerzero_option = 0x00030100110100000000000000000000000000030d40;
    mapping (string => string) rpc_urls;


    // the identifiers of the forks
    uint256 chain_fork_eth;
    uint256 chain_fork_polygon;

    //Access variables from .env file via vm.envString("varname")
    //Replace ALCHEMY_KEY by your alchemy key or Etherscan key, change RPC url if need
    //inside your .env file e.g:
    string MAINNET_RPC_URL = 'https://eth.llamarpc.com';
    string POLYGON_RPC_URL = 'https://polygon.llamarpc.com';
    //string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
    //string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");

    // create two _different_ forks during setup
    function setUp() public {
        chain_fork_eth = vm.createFork(MAINNET_RPC_URL, 19_460_000);
        chain_fork_polygon = vm.createFork(POLYGON_RPC_URL, 54_800_000);

        layerzero_endpoints["ethereum"] = LayerzeroEndpoint({
        endpoint: 0x1a44076050125825900e736c501f859c50fE728c,
        endpointId: 30101
        });
        layerzero_endpoints["polygon"] = LayerzeroEndpoint({
            endpoint: 0x1a44076050125825900e736c501f859c50fE728c,
            endpointId: 30109
        });
        layerzero_endpoints["sepolia"] = LayerzeroEndpoint({
            endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            endpointId: 40161
        });
        layerzero_endpoints["mumbai"] = LayerzeroEndpoint({
            endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            endpointId: 40109
        });
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = bytes1(uint8(87 + value % 16 + ((value % 16) / 10) * 39));
            value /= 16;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
/*
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
*/

    function testLayerZeroDebug() public {
        address mock_sender = 0x3333333333333333333333333333333333333333;
        bytes memory my_payload = abi.encodePacked(uint(1234));
        bytes32 messageId = keccak256(my_payload);

        vm.selectFork(chain_fork_eth);
        /*
            endpointId: 30101
            endpoint: 0x1a44076050125825900e736c501f859c50fe728c
        */
        address endpoint_chain_eth = layerzero_endpoints["ethereum"].endpoint;
        LayerZeroMessageEndpoint sender = new LayerZeroMessageEndpoint(endpoint_chain_eth);

        sender.setPeer(layerzero_endpoints["polygon"].endpointId, bytes32(uint256(uint160(address(mock_sender))) << 96));

        bytes memory optionValue = "\x00\x03\x01\x00\x11\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x0d\x40";
        sender.setMyOption(optionValue);

        console.logString("print peer sender");
        console.logAddress(address(sender));
        console.logAddress(address(mock_sender));
        bytes32 sender_peer = sender.peers(layerzero_endpoints["polygon"].endpointId);
        sender.setEidMapping("polygon", layerzero_endpoints["polygon"].endpointId);
        console.logBytes32(sender_peer);
        bytes32 messageid = sender.sendMessage{value:10**18}("polygon", toHexString(uint256(uint160((address(mock_sender)))), 20), my_payload);
    }

    function testLayerZero() public {
        address mock_sender = 0x3333333333333333333333333333333333333333;
        bytes memory my_payload = abi.encodePacked(uint(1234), "hello im sender");
        bytes32 messageId = keccak256(my_payload);

        vm.selectFork(chain_fork_eth);
        /*
            endpointId: 30101
            endpoint: 0x1a44076050125825900e736c501f859c50fe728c
        */
        address endpoint_chain_eth = layerzero_endpoints["ethereum"].endpoint;
        LayerZeroMessageEndpoint sender = new LayerZeroMessageEndpoint(endpoint_chain_eth);

        vm.selectFork(chain_fork_polygon);
        /*
            endpointId: 30109
            endpoint: 0x1a44076050125825900e736c501f859c50fe728c
        */
        address endpoint_chain_polygon = layerzero_endpoints["polygon"].endpoint;
        LayerZeroMessageEndpoint receiver = new LayerZeroMessageEndpoint(endpoint_chain_polygon);

        // send a message
        vm.selectFork(chain_fork_eth);

        sender.setPeer(layerzero_endpoints["polygon"].endpointId, bytes32(uint256(uint160(address(receiver))) << 96));

        bytes memory optionValue = "\x00\x03\x01\x00\x11\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x0d\x40";
        sender.setMyOption(optionValue);

        console.logString("print peer sender");
        console.logAddress(address(sender));
        console.logAddress(address(receiver));
        bytes32 sender_peer = sender.peers(layerzero_endpoints["polygon"].endpointId);
        sender.setEidMapping("polygon", layerzero_endpoints["polygon"].endpointId);
        console.logBytes32(sender_peer);
        bytes32 messageid = sender.sendMessage{value:10**18}("polygon", toHexString(uint256(uint160((address(receiver)))), 20), my_payload);
        // // receive a message
        // vm.selectFork(chain_fork_polygon);
        // // // set peer
        // // receiver.setPeer(1, bytes32(uint256(uint160(mock_sender)) << 96));
        // receiver.setPeer(layerzero_endpoints["ethereum"].endpointId, bytes32(uint256(uint160(address(sender))) << 96));
        // receiver.setEidMapping("chain2", 1);
        // console.logString("print peer receiver");
        // console.logAddress(address(receiver));
        // bytes32 recv_peer = receiver.peers(1);
        // console.logBytes32(recv_peer);

        // vm.deal(endpoint_chain_polygon,10**18);
        // vm.prank(endpoint_chain_polygon);
        // Origin memory origin = Origin({
        //     srcEid: layerzero_endpoints["ethereum"].endpointId,
        //     sender: bytes32(uint256(uint160(address(sender))) << 96),
        //     nonce: 0
        // });
        // receiver.lzReceive(origin, bytes32(hex"1234"), my_payload, mock_sender, bytes(hex"00"));

        // bytes memory new_payload = receiver.deliverMessage(messageId);
        // console.logBytes(my_payload);
        // console.logBytes(new_payload);

        // // expect message
        // assertEq(abi.encode(new_payload), abi.encode(my_payload));

    }


}
