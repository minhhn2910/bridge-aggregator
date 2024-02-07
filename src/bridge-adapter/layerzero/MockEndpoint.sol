pragma solidity ^0.8.22;
import "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingChannel.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingComposer.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingContext.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
contract MockEndpointLayerZero is ILayerZeroEndpointV2 {
  function quote(MessagingParams calldata _params, address _sender) external view returns (MessagingFee memory){
    return MessagingFee(0, 0);
  }

/*
  struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}
*/

    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory){
        return MessagingReceipt(0, 0, MessagingFee(0, 0));
    }

    function verify(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external {}

    function verifiable(Origin calldata _origin, address _receiver) external view returns (bool) {
        return true;
    }

    function initializable(Origin calldata _origin, address _receiver) external view returns (bool){
        return true;
    }

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable{}

    // oapp can burn messages partially by calling this function with its own business logic if messages are verified in order
   function clear(address _oapp, Origin calldata _origin, bytes32 _guid, bytes calldata _message) external{}

    function setLzToken(address _lzToken) external {}

    function lzToken() external view returns (address) {
        return address(0);
    }

    function nativeToken() external view returns (address){
        return address(0);
    }

    function setDelegate(address _delegate) external{}

    // IMessageLibManager.sol
     function registerLibrary(address _lib) external{}

    function isRegisteredLibrary(address _lib) external view returns (bool){ return true;}

    function getRegisteredLibraries() external view returns (address[] memory){return new address[](0);}

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external {}

    function defaultSendLibrary(uint32 _eid) external view returns (address){return address(0);}

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint256 _timeout) external {}

    function defaultReceiveLibrary(uint32 _eid) external view returns (address) {return address(0);}

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint256 _expiry) external {}

    function defaultReceiveLibraryTimeout(uint32 _eid) external view returns (address lib, uint256 expiry) {
        return (address(0), 0);
    }

    function isSupportedEid(uint32 _eid) external view returns (bool) {return true;}

    function isValidReceiveLibrary(address _receiver, uint32 _eid, address _lib) external view returns (bool) {return true;}

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(address _oapp, uint32 _eid, address _newLib) external {}

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib) {return address(0);}

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool) {return true;}

    function setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod) external {}

    function getReceiveLibrary(address _receiver, uint32 _eid) external view returns (address lib, bool isDefault) {
        return (address(0), true);
    }

    function setReceiveLibraryTimeout(address _oapp, uint32 _eid, address _lib, uint256 _gracePeriod) external {}

    function receiveLibraryTimeout(address _receiver, uint32 _eid) external view returns (address lib, uint256 expiry) {
        return (address(0), 0);
    }

    function setConfig(address _oapp, address _lib, SetConfigParam[] calldata _params) external {}

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config) {
        return new bytes(0);
    }
    //IMessagingChannel.sol

    function eid() external view returns (uint32) {return uint32(0);}

    // this is an emergency function if a message cannot be verified for some reasons
    // required to provide _nextNonce to avoid race condition
    function skip(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce) external {}

    function nilify(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce, bytes32 _payloadHash) external {}

    function burn(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce, bytes32 _payloadHash) external {}

    function nextGuid(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (bytes32) {
        return bytes32(0);
    }

    function inboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64) {
        return uint64(0);
    }

    function outboundNonce(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (uint64) {
        return uint64(0);
    }

    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32) {
        return bytes32(0);
    }

    function lazyInboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64) {
        return uint64(0);
    }
    //IMessagingComposer.sol
        function composeQueue(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index
    ) external view returns (bytes32 messageHash) {
        return bytes32(0);
    }

    function sendCompose(address _to, bytes32 _guid, uint16 _index, bytes calldata _message) external {}

    function lzCompose(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable {}
    // IMessagingContext.sol
    function isSendingMessage() external view returns (bool) {return true;}

    function getSendContext() external view returns (uint32 dstEid, address sender) {
        return (uint32(0), address(0));
    }
}

