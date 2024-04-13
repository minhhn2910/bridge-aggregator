pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageEndpoint} from "src/bridge-adapter/MessageEndpoint.sol";
// interface MessageEndpoint {
//     function sendMessage(string calldata destinationChain, string calldata destinationAddress, bytes calldata payload) external payable;
//     function deliverMessage(bytes32 messageId) external view returns (bytes memory);
// }

contract SimpleAggregator is Ownable {
    MessageEndpoint[] public endpoints;

    struct EndpointResult {
        bytes32 messageId;
        bytes payload;
    }

    uint public theshold = 2; // Threshold for verification

    mapping(bytes32 => EndpointResult) public results;

    constructor(address[] memory _endpoints) Ownable(msg.sender){
        for(uint i = 0; i < _endpoints.length; i++) {
            endpoints.push(MessageEndpoint(_endpoints[i]));
        }
    }

    function addEndpoint(MessageEndpoint _endpoint) public onlyOwner {
        endpoints.push(_endpoint);
    }
    function setThreshold(uint _threshold) public onlyOwner {
        theshold = _threshold;
    }
    function removeEndpoint(MessageEndpoint _endpoint) public onlyOwner {
        for (uint i = 0; i < endpoints.length; i++) {
            if (endpoints[i] == _endpoint) {
                endpoints[i] = endpoints[endpoints.length - 1];
                endpoints.pop(); // Reduces the length of the array by 1
                break; // Assuming no duplicates, we can exit the loop once we've found and removed the endpoint
            }
        }
    }

    function sendMultipleMessages(string calldata destinationChain, string calldata destinationAddress, bytes calldata payload) public payable onlyOwner {
        for (uint i = 0; i < endpoints.length; i++) {
            endpoints[i].sendMessage{value: msg.value/endpoints.length}(destinationChain, destinationAddress, payload);
        }
    }

    function aggregateMultipleMessages(bytes32 messageId) public view returns (bool verified, bytes memory finalPayload) {
        bytes memory referencePayload;
        uint matchCount = 0;
        bool referencePayloadSet = false;

        for (uint i = 0; i < endpoints.length; i++) {
            bytes memory currentPayload = endpoints[i].deliverMessage(messageId);

            // Skip blank payloads
            if (currentPayload.length == 0) continue;

            if (!referencePayloadSet) {
                // Set the first non-blank payload as the reference
                referencePayload = currentPayload;
                referencePayloadSet = true;
                matchCount = 1; // Include the reference payload in the count
            } else if (keccak256(currentPayload) == keccak256(referencePayload)) {
                // Increment matchCount if the current payload matches the reference payload
                matchCount++;
            }
        }

        // Determine if the number of matches meets the threshold N
        verified = matchCount >= theshold;
        // if (verified) {
        finalPayload = referencePayload;
        // }

        return (verified, finalPayload);
    }

    receive () external payable {}

}
