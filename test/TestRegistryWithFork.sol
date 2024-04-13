// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";


import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {MockRouterChainlink} from "src/bridge-adapter/chainlink/MockRouter.sol";
import {ChainlinkMessageEndpoint} from "src/bridge-adapter/chainlink/ChainlinkMessageEndpoint.sol";
import {IRouter} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouter.sol";
import {MockToken} from "src/utils/MockToken.sol";


import {MockEndpointLayerZero} from "src/bridge-adapter/layerzero/MockEndpoint.sol";
import {LayerZeroMessageEndpoint} from "src/bridge-adapter/layerzero/LayerZeroMessageEndpoint.sol";

import {MockGasServiceAxelar} from "src/bridge-adapter/axelar/MockGasService.sol";
import {MockGatewayAxelar} from "src/bridge-adapter/axelar/MockGateway.sol";
import {AxelarMessageEndpoint} from "src/bridge-adapter/axelar/AxelarMessageEndpoint.sol";
import {MockAxelarAuth} from "src/bridge-adapter/axelar/MockAxelarAuth.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";

import {MockRelayerWormhole} from "src/bridge-adapter/wormhole/MockRelayer.sol";
import {WormholeMessageEndpoint} from "src/bridge-adapter/wormhole/WormholeMessageEndpoint.sol";

import {Origin, ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";



import {SimpleAggregator} from "src/SimpleAggregator.sol";
import {SimpleRegistry} from "src/SimpleRegistry.sol";
import {SimpleToken} from "src/SimpleToken.sol";
contract ForkTest is Test {
    struct LayerzeroEndpoint{
        address endpoint;
        uint32 endpointId;
    }
    struct ChainlinkEndpoint{
        address routerAddress;
        uint64 chainSelector;
    }
    struct ChainlinkLane{
        address onRampAddress;
        address offRampAddress;
        uint64 srcChainSelector;
        uint64 destChainSelector;
    }
    struct AxelarEndpoint{
        string chainName;
        address gateway;
        address gasService;
        address authModule;
        uint256 chainId;
    }
    mapping (string => LayerzeroEndpoint) layerzero_endpoints;
    mapping (string => ChainlinkEndpoint) chainlink_endpoints;
    mapping (string => ChainlinkLane) chainlink_lanes;
    mapping (string => AxelarEndpoint) axelar_endpoints;

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
        chainlink_endpoints["ethereum"] = ChainlinkEndpoint({
            routerAddress: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
            chainSelector: 5009297550715157269
        });
        chainlink_endpoints["polygon"] = ChainlinkEndpoint({
            routerAddress: 0x849c5ED5a80F5B408Dd4969b78c2C8fdf0565Bfe,
            chainSelector: 4051577828743386545
        });
        chainlink_lanes["ethpolygon"] = ChainlinkLane({
            onRampAddress: 0x35F0ca9Be776E4B38659944c257bDd0ba75F1B8B,
            offRampAddress: 0x45320085fF051361D301eC1044318213A5387A15,
            //https://polygonscan.com/address/0x849c5ED5a80F5B408Dd4969b78c2C8fdf0565Bfe#readContract
            srcChainSelector: 5009297550715157269,
            destChainSelector: 4051577828743386545
        });
        chainlink_lanes["polygoneth"] = ChainlinkLane({
            onRampAddress: 0xFd77c53AA4eF0E3C01f5Ac012BF7Cc7A3ECf5168,
            offRampAddress: 0x0af338F0E314c7551bcE0EF516d46d855b0Ee395,
            //https://etherscan.io/address/0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D#readContract
            srcChainSelector: 4051577828743386545,
            destChainSelector: 5009297550715157269
        });

        axelar_endpoints["ethereum"] = AxelarEndpoint({
            chainName: "Ethereum",
            gateway: 0x4F4495243837681061C4743b74B3eEdf548D56A5,
            gasService: 0x2d5d7d31F671F86C782533cc367F14109a082712,
            authModule: 0xE3B83f79Fbf01B25659f8A814945aB82186A8AD0,
            chainId: 1
        });
        axelar_endpoints["polygon"] = AxelarEndpoint({
            chainName: "Polygon",
            gateway: 0x6f015F16De9fC8791b234eF68D486d2bF203FBA8,
            gasService: 0x2d5d7d31F671F86C782533cc367F14109a082712,
            authModule: 0xFcf8b865177c45A86a4977e518B44a1eD90191bd,
            chainId: 137
        });

    }
    struct TokenMessage {
        address receiver;
        uint256 amount;
        bool isMint;
    }
    function testAggregatorFork() public {

        bool verified; bytes memory finalPayload;
        TokenMessage memory tokenMessage = TokenMessage({
            receiver: address(0x1111111111111111111111111111111111111111),
            amount: 100,
            isMint: true
        });
        // bytes memory my_payload = abi.encodePacked(uint(1234), "hello im sender test");
        bytes memory my_payload = abi.encode(tokenMessage);
        bytes32 messageId = keccak256(my_payload);

        // Axelar
        vm.selectFork(chain_fork_eth);
        AxelarMessageEndpoint axelar_sender = new AxelarMessageEndpoint(axelar_endpoints["ethereum"].gateway,
                                     axelar_endpoints["ethereum"].gasService);
        string memory axelar_sender_addr_string = vm.toString(address(axelar_sender));
        vm.selectFork(chain_fork_polygon);
        AxelarMessageEndpoint axelar_receiver = new AxelarMessageEndpoint(axelar_endpoints["polygon"].gateway,
                                     axelar_endpoints["polygon"].gasService);
        string memory axelar_receiver_addr_string = vm.toString(address(axelar_receiver));

        // Chainlink
        // setup

        vm.selectFork(chain_fork_eth);
        ChainlinkMessageEndpoint chainlink_sender = new ChainlinkMessageEndpoint(chainlink_endpoints["ethereum"].routerAddress);
        chainlink_sender.setChainMapping("polygon", chainlink_endpoints["polygon"].chainSelector);

        vm.selectFork(chain_fork_polygon);
        ChainlinkMessageEndpoint chainlink_receiver = new ChainlinkMessageEndpoint(chainlink_endpoints["polygon"].routerAddress);
        chainlink_receiver.setChainMapping("ethereum", chainlink_endpoints["ethereum"].chainSelector);



        // LayzerZero
        vm.selectFork(chain_fork_eth);

        address endpoint_chain_eth = layerzero_endpoints["ethereum"].endpoint;
        LayerZeroMessageEndpoint layerzero_sender = new LayerZeroMessageEndpoint(endpoint_chain_eth);

        vm.selectFork(chain_fork_polygon);

        address endpoint_chain_polygon = layerzero_endpoints["polygon"].endpoint;
        LayerZeroMessageEndpoint layerzero_receiver = new LayerZeroMessageEndpoint(endpoint_chain_polygon);

        vm.selectFork(chain_fork_eth);

        //setup sender side
        chainlink_sender.setAddressMapping("receiver_address", address(chainlink_receiver));

        layerzero_sender.setPeer(layerzero_endpoints["polygon"].endpointId, bytes32(uint256(uint160(address(layerzero_receiver)))));
        bytes memory optionValue = hex'0003010011010000000000000000000000000000ea60';
        layerzero_sender.setMyOption(optionValue);
        layerzero_sender.setEidMapping("polygon", layerzero_endpoints["polygon"].endpointId);


        // use aggregator
        address [] memory senders = new address[](3);
        senders[0] = address(axelar_sender);
        senders[1] = address(chainlink_sender);
        senders[2] = address(layerzero_sender);
        SimpleAggregator my_sender_aggregator = new SimpleAggregator(senders);
        my_sender_aggregator.sendMultipleMessages{value:10**18}("polygon", "receiver_address", my_payload);

        vm.selectFork(chain_fork_polygon);
        address [] memory receivers = new address[](3);
        receivers[0] = address(axelar_receiver);
        receivers[1] = address(chainlink_receiver);
        receivers[2] = address(layerzero_receiver);

        SimpleAggregator my_receiver_aggregator = new SimpleAggregator(receivers);

        SimpleRegistry my_receiver_registry = new SimpleRegistry(payable(my_receiver_aggregator));
        // may need to set owner or create aggregator inside constructor

        // receive a message Axelar
        MockAxelarAuth polygon_auth = MockAxelarAuth(axelar_endpoints["polygon"].authModule);
        deployCodeTo("MockAxelarAuth.sol", axelar_endpoints["polygon"].authModule);
        bool res2 = polygon_auth.validateProof(messageId, my_payload);
        console.log("validateProof %s", res2);
        IAxelarGateway axelar_gateway = IAxelarGateway(axelar_endpoints["polygon"].gateway);
        // Prepare payload with dynamic arrays
        bytes32[] memory commandIds = new bytes32[](1);
        commandIds[0] = messageId;  // Assuming messageId is a bytes32 variable
        string[] memory commands = new string[](1);
        commands[0] = "approveContractCall";  // Command as a string
        bytes[] memory params = new bytes[](1);

        bytes memory params_data = abi.encode(axelar_endpoints["ethereum"].chainName, axelar_sender_addr_string,
                                        address(axelar_receiver), keccak256(my_payload), messageId, 1);
        params[0] = params_data;
        bytes memory data = abi.encode(axelar_endpoints["polygon"].chainId, commandIds, commands, params);

        bytes32 payloadHash = keccak256(my_payload);
        bytes memory encoded_data_with_proof = abi.encode(data, my_payload);
        axelar_gateway.execute(encoded_data_with_proof);
        axelar_receiver.execute(messageId, axelar_endpoints["ethereum"].chainName,
                            axelar_sender_addr_string, my_payload);


        (verified, finalPayload) = my_receiver_aggregator.aggregateMultipleMessages(messageId);
        console.logBool(verified);
        console.logBytes(finalPayload);
        // expect not verified
        assertEq(verified, false);
        assertEq(abi.encode(finalPayload), abi.encode(my_payload));


        // receive a message Chainlink

        chainlink_receiver.setAddressMapping("sender_address", address(chainlink_sender));
        address receiver_offramp = chainlink_lanes["ethpolygon"].offRampAddress;

        // simulating offramp submitting message
        uint64 destinationChainSelector = chainlink_lanes["ethpolygon"].destChainSelector;

        // gasForCallExactCheck // check 1
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: chainlink_lanes["ethpolygon"].srcChainSelector,
            sender: abi.encode(address(chainlink_sender)),
            data: my_payload,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        vm.deal(address(receiver_offramp),10**18);
        vm.prank(address(receiver_offramp));

        IRouter router = IRouter(chainlink_endpoints["polygon"].routerAddress);
        (bool success, bytes memory retData, uint256 gasUsed) = router.routeMessage(message, 100, 1000000, address(chainlink_receiver));


        (verified, finalPayload) = my_receiver_aggregator.aggregateMultipleMessages(messageId);
        console.logBool(verified);
        console.logBytes(finalPayload);
        // expect verified
        assertEq(verified, true);
        // expect message
        assertEq(abi.encode(finalPayload), abi.encode(my_payload));


        // set threshold to 3 to test
        my_receiver_aggregator.setThreshold(3);
        (verified, finalPayload) = my_receiver_aggregator.aggregateMultipleMessages(messageId);
        assertEq(verified, false);
        console.logBool(verified);
        console.logBytes(finalPayload);

        // receive a message LayerZero

        layerzero_receiver.setPeer(layerzero_endpoints["ethereum"].endpointId, bytes32(uint256(uint160(address(layerzero_sender)))));

        console.logString("print peer receiver");
        console.logAddress(address(layerzero_receiver));
        bytes32 recv_peer = layerzero_receiver.peers(1);
        console.logBytes32(recv_peer);

        vm.deal(endpoint_chain_polygon,10**18);
        vm.prank(endpoint_chain_polygon);
        Origin memory origin = Origin({
            srcEid: layerzero_endpoints["ethereum"].endpointId,
            sender: bytes32(uint256(uint160(address(layerzero_sender)))),
            nonce: 0
        });

        layerzero_receiver.lzReceive(origin, bytes32(hex"1234"), my_payload, address(layerzero_sender), bytes(hex"00"));
        (verified, finalPayload) = my_receiver_aggregator.aggregateMultipleMessages(messageId);
        // expect verified
        assertEq(verified, true);
        // expect message
        assertEq(abi.encode(finalPayload), abi.encode(my_payload));

        SimpleToken token = my_receiver_registry.token();
        // precondition
        assertEq(token.balanceOf(address(0x1111111111111111111111111111111111111111)), 0);
        // minting action
        my_receiver_registry.receiveRemoteMessage(messageId);
        // postcondition
        assertEq(token.balanceOf(address(0x1111111111111111111111111111111111111111)), 100);

    }
}
