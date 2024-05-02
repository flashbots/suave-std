// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./utils/RLPWriter.sol";
import "./suavelib/Suave.sol";
import "Solidity-RLP/RLPReader.sol";
import "solady/src/utils/LibString.sol";

/// @notice Transactions is a library with utilities to encode, decode and sign Ethereum transactions.
library Transactions {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    /// @notice EIP-155 transaction structure.
    /// @param to is the target address.
    /// @param gas is the gas limit.
    /// @param gasPrice is the gas price.
    /// @param value is the transfer value in gwei.
    /// @param nonce is the latest nonce of the sender.
    /// @param data is the transaction data.
    /// @param chainId is the id of the chain where the transaction will be executed.
    /// @param r is the 'r' signature value.
    /// @param s is the 's' signature value.
    /// @param v is the 'v' signature value.
    struct EIP155 {
        address to;
        uint256 gas;
        uint256 gasPrice;
        uint256 value;
        uint256 nonce;
        bytes data;
        uint256 chainId;
        bytes32 r;
        bytes32 s;
        uint256 v;
    }

    /// @notice EIP-155 transaction request structure.
    /// @param to is the target address.
    /// @param gas is the gas limit.
    /// @param gasPrice is the gas price.
    /// @param value is the transfer value in gwei.
    /// @param nonce is the latest nonce of the sender.
    /// @param data is the transaction data.
    /// @param chainId is the id of the chain where the transaction will be executed.
    struct EIP155Request {
        address to;
        uint256 gas;
        uint256 gasPrice;
        uint256 value;
        uint256 nonce;
        bytes data;
        uint256 chainId;
    }

    /// @notice EIP-1559 transaction structure.
    /// @param to is the target address.
    /// @param gas is the gas limit.
    /// @param maxFeePerGas is the maximum fee per gas.
    /// @param maxPriorityFeePerGas is the maximum priority fee per gas.
    /// @param value is the transfer value in gwei.
    /// @param nonce is the latest nonce of the sender.
    /// @param data is the transaction data.
    /// @param chainId is the id of the chain where the transaction will be executed.
    /// @param accessList is the access list.
    /// @param r is the 'r' signature value.
    /// @param s is the 's' signature value.
    /// @param v is the 'v' signature value.
    struct EIP1559 {
        address to;
        uint256 gas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 value;
        uint256 nonce;
        bytes data;
        uint256 chainId;
        bytes accessList;
        bytes32 r;
        bytes32 s;
        uint256 v;
    }

    /// @notice EIP-1559 transaction request structure.
    /// @param to is the target address.
    /// @param gas is the gas limit.
    /// @param maxFeePerGas is the maximum fee per gas.
    /// @param maxPriorityFeePerGas is the maximum priority fee per gas.
    /// @param value is the transfer value in gwei.
    /// @param nonce is the latest nonce of the sender.
    /// @param data is the transaction data.
    /// @param chainId is the id of the chain where the transaction will be executed.
    /// @param accessList is the access list.
    struct EIP1559Request {
        address to;
        uint256 gas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 value;
        uint256 nonce;
        bytes data;
        uint256 chainId;
        bytes accessList;
    }

    /// @notice encode a EIP-155 transaction in RLP.
    /// @param txStruct is the transaction structure.
    /// @return output the encoded RLP bytes.
    function encodeRLP(EIP155 memory txStruct) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](9);

        items[0] = RLPWriter.writeUint(txStruct.nonce);
        items[1] = RLPWriter.writeUint(txStruct.gasPrice);
        items[2] = RLPWriter.writeUint(txStruct.gas);

        if (txStruct.to == address(0)) {
            items[3] = RLPWriter.writeBytes(bytes(""));
        } else {
            items[3] = RLPWriter.writeAddress(txStruct.to);
        }
        items[4] = RLPWriter.writeUint(txStruct.value);
        items[5] = RLPWriter.writeBytes(txStruct.data);
        items[6] = RLPWriter.writeUint(txStruct.v);
        items[7] = RLPWriter.writeBytes(abi.encodePacked(txStruct.r));
        items[8] = RLPWriter.writeBytes(abi.encodePacked(txStruct.s));

        return RLPWriter.writeList(items);
    }

    /// @notice encode a EIP-1559 request transaction in RLP.
    /// @param txStruct is the transaction structure.
    /// @return output the encoded RLP bytes.
    function encodeRLP(EIP155Request memory txStruct) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](9);

        items[0] = RLPWriter.writeUint(txStruct.nonce);
        items[1] = RLPWriter.writeUint(txStruct.gasPrice);
        items[2] = RLPWriter.writeUint(txStruct.gas);

        if (txStruct.to == address(0)) {
            items[3] = RLPWriter.writeBytes(bytes(""));
        } else {
            items[3] = RLPWriter.writeAddress(txStruct.to);
        }
        items[4] = RLPWriter.writeUint(txStruct.value);
        items[5] = RLPWriter.writeBytes(txStruct.data);
        items[6] = RLPWriter.writeUint(txStruct.chainId);
        items[7] = RLPWriter.writeBytes("");
        items[8] = RLPWriter.writeBytes("");

        return RLPWriter.writeList(items);
    }

    /// @notice encode a EIP-1559 transaction in RLP.
    /// @param txStruct is the transaction structure.
    /// @return output the encoded RLP bytes.
    function encodeRLP(EIP1559 memory txStruct) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](12);

        items[0] = RLPWriter.writeUint(txStruct.chainId);
        items[1] = RLPWriter.writeUint(txStruct.nonce);
        items[2] = RLPWriter.writeUint(txStruct.maxPriorityFeePerGas);
        items[3] = RLPWriter.writeUint(txStruct.maxFeePerGas);
        items[4] = RLPWriter.writeUint(txStruct.gas);

        if (txStruct.to == address(0)) {
            items[5] = RLPWriter.writeBytes(bytes(""));
        } else {
            items[5] = RLPWriter.writeAddress(txStruct.to);
        }

        items[6] = RLPWriter.writeUint(txStruct.value);
        items[7] = RLPWriter.writeBytes(txStruct.data);

        if (txStruct.accessList.length == 0) {
            items[8] = hex"c0"; // Empty list encoding
        } else {
            items[8] = RLPWriter.writeBytes(txStruct.accessList);
        }

        items[9] = RLPWriter.writeUint(txStruct.v);
        items[10] = RLPWriter.writeBytes(abi.encodePacked(txStruct.r));
        items[11] = RLPWriter.writeBytes(abi.encodePacked(txStruct.s));

        bytes memory rlpTxn = RLPWriter.writeList(items);

        bytes memory txn = new bytes(1 + rlpTxn.length);
        txn[0] = 0x02;

        for (uint256 i = 0; i < rlpTxn.length; ++i) {
            txn[i + 1] = rlpTxn[i];
        }

        return txn;
    }

    /// @notice encode a EIP-1559 request transaction in RLP.
    /// @param txStruct is the transaction structure.
    /// @return output the encoded RLP bytes.
    function encodeRLP(EIP1559Request memory txStruct) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](9);

        items[0] = RLPWriter.writeUint(txStruct.chainId);
        items[1] = RLPWriter.writeUint(txStruct.nonce);
        items[2] = RLPWriter.writeUint(txStruct.maxPriorityFeePerGas);
        items[3] = RLPWriter.writeUint(txStruct.maxFeePerGas);
        items[4] = RLPWriter.writeUint(txStruct.gas);

        if (txStruct.to == address(0)) {
            items[5] = RLPWriter.writeBytes(bytes(""));
        } else {
            items[5] = RLPWriter.writeAddress(txStruct.to);
        }

        items[6] = RLPWriter.writeUint(txStruct.value);
        items[7] = RLPWriter.writeBytes(txStruct.data);

        if (txStruct.accessList.length == 0) {
            items[8] = hex"c0"; // Empty list encoding
        } else {
            items[8] = RLPWriter.writeBytes(txStruct.accessList);
        }

        bytes memory rlpTxn = RLPWriter.writeList(items);

        bytes memory txn = new bytes(1 + rlpTxn.length);
        txn[0] = 0x02;

        for (uint256 i = 0; i < rlpTxn.length; ++i) {
            txn[i + 1] = rlpTxn[i];
        }

        return txn;
    }

    /// @notice decode a EIP-155 transaction from RLP.
    /// @param rlp is the encoded RLP bytes.
    /// @return txStruct the transaction structure.
    function decodeRLP_EIP155(bytes memory rlp) internal pure returns (EIP155 memory) {
        EIP155 memory txStruct;

        RLPReader.RLPItem[] memory ls = rlp.toRlpItem().toList();
        require(ls.length == 9, "invalid transaction");

        txStruct.nonce = ls[0].toUint();
        txStruct.gasPrice = ls[1].toUint();
        txStruct.gas = ls[2].toUint();

        if (ls[3].toRlpBytes().length == 1) {
            txStruct.to = address(0);
        } else {
            txStruct.to = ls[3].toAddress();
        }

        txStruct.value = ls[4].toUint();
        txStruct.data = ls[5].toBytes();
        txStruct.v = ls[6].toUint();
        txStruct.r = bytesToBytes32(ls[7].toBytes());
        txStruct.s = bytesToBytes32(ls[8].toBytes());

        return txStruct;
    }

    /// @notice decode a EIP-155 request transaction from RLP.
    /// @param rlp is the encoded RLP bytes.
    /// @return txStruct the transaction structure.
    function decodeRLP_EIP155Request(bytes memory rlp) internal pure returns (EIP155Request memory) {
        EIP155Request memory txStruct;

        RLPReader.RLPItem[] memory ls = rlp.toRlpItem().toList();
        require(ls.length == 9, "invalid transaction");

        txStruct.nonce = ls[0].toUint();
        txStruct.gasPrice = ls[1].toUint();
        txStruct.gas = ls[2].toUint();

        if (ls[3].toRlpBytes().length == 1) {
            txStruct.to = address(0);
        } else {
            txStruct.to = ls[3].toAddress();
        }

        txStruct.value = ls[4].toUint();
        txStruct.data = ls[5].toBytes();
        txStruct.chainId = uint64(ls[6].toUint());

        return txStruct;
    }

    /// @notice decode a EIP-1559 transaction from RLP.
    /// @param rlp is the encoded RLP bytes.
    /// @return txStruct the transaction structure.
    function decodeRLP_EIP1559(bytes memory rlp) internal pure returns (EIP1559 memory) {
        EIP1559 memory txStruct;

        bytes memory rlpWithoutPrefix = new bytes(rlp.length - 1);

        for (uint256 i = 0; i < rlp.length - 1; ++i) {
            rlpWithoutPrefix[i] = rlp[i + 1];
        }

        RLPReader.RLPItem[] memory ls = rlpWithoutPrefix.toRlpItem().toList();
        require(ls.length == 12, "invalid transaction");

        txStruct.chainId = uint64(ls[0].toUint());
        txStruct.nonce = uint64(ls[1].toUint());
        txStruct.maxPriorityFeePerGas = uint64(ls[2].toUint());
        txStruct.maxFeePerGas = uint64(ls[3].toUint());
        txStruct.gas = uint64(ls[4].toUint());

        if (ls[5].toRlpBytes().length == 1) {
            txStruct.to = address(0);
        } else {
            txStruct.to = ls[5].toAddress();
        }

        txStruct.value = uint64(ls[6].toUint());
        txStruct.data = ls[7].toBytes();
        txStruct.accessList = ls[8].toBytes();
        txStruct.v = uint64(ls[9].toUint());
        txStruct.r = bytesToBytes32(ls[10].toBytes());
        txStruct.s = bytesToBytes32(ls[11].toBytes());

        return txStruct;
    }

    /// @notice decode a EIP-1559 request transaction from RLP.
    /// @param rlp is the encoded RLP bytes.
    /// @return txStruct the transaction structure.
    function decodeRLP_EIP1559Request(bytes memory rlp) internal pure returns (EIP1559Request memory) {
        EIP1559Request memory txStruct;

        bytes memory rlpWithoutPrefix = new bytes(rlp.length - 1);

        for (uint256 i = 0; i < rlp.length - 1; ++i) {
            rlpWithoutPrefix[i] = rlp[i + 1];
        }

        RLPReader.RLPItem[] memory ls = rlpWithoutPrefix.toRlpItem().toList();
        require(ls.length == 8, "invalid transaction");

        txStruct.chainId = uint64(ls[0].toUint());
        txStruct.nonce = uint64(ls[1].toUint());
        txStruct.maxPriorityFeePerGas = uint64(ls[2].toUint());
        txStruct.maxFeePerGas = uint64(ls[3].toUint());
        txStruct.gas = uint64(ls[4].toUint());

        if (ls[5].toRlpBytes().length == 1) {
            txStruct.to = address(0);
        } else {
            txStruct.to = ls[5].toAddress();
        }

        txStruct.value = uint64(ls[6].toUint());
        txStruct.data = ls[7].toBytes();

        return txStruct;
    }

    function bytesToBytes32(bytes memory inBytes) internal pure returns (bytes32 out) {
        require(inBytes.length == 32, "bytesToBytes32: invalid input length");
        assembly {
            out := mload(add(inBytes, 32))
        }
    }

    /// @notice sign a EIP-155 transaction request.
    /// @param request is the transaction request.
    /// @param signingKey is the private key to sign the transaction.
    /// @return response the signed transaction.
    function signTxn(Transactions.EIP1559Request memory request, string memory signingKey)
        internal
        returns (Transactions.EIP1559 memory response)
    {
        bytes memory rlp = Transactions.encodeRLP(request);
        bytes memory hash = abi.encodePacked(keccak256(rlp));
        bytes memory signature = Suave.signMessage(hash, Suave.CryptoSignature.SECP256, signingKey);
        (uint8 v, bytes32 r, bytes32 s) = decodeSignature(signature);

        response.to = request.to;
        response.gas = request.gas;
        response.maxFeePerGas = request.maxFeePerGas;
        response.maxPriorityFeePerGas = request.maxPriorityFeePerGas;
        response.value = request.value;
        response.nonce = request.nonce;
        response.data = request.data;
        response.chainId = request.chainId;
        response.accessList = request.accessList;
        response.v = v;
        response.r = r;
        response.s = s;

        return response;
    }

    /// @notice sign a EIP-155 transaction request.
    /// @param request is the transaction request.
    /// @param signingKey is the private key to sign the transaction.
    /// @return response the signed transaction.
    function signTxn(Transactions.EIP155Request memory request, string memory signingKey)
        internal
        returns (Transactions.EIP155 memory response)
    {
        bytes memory rlp = Transactions.encodeRLP(request);
        bytes memory hash = abi.encodePacked(keccak256(rlp));
        bytes memory signature = Suave.signMessage(hash, Suave.CryptoSignature.SECP256, signingKey);

        // TODO: check overflow
        uint64 chainIdMul = uint64(request.chainId) * 2;
        (uint8 v, bytes32 r, bytes32 s) = decodeSignature(signature);

        uint64 v64 = uint64(v) + 35;
        v64 += chainIdMul;

        response.to = request.to;
        response.gas = request.gas;
        response.gasPrice = request.gasPrice;
        response.value = request.value;
        response.nonce = request.nonce;
        response.data = request.data;
        response.chainId = request.chainId;
        response.v = v64;
        response.r = r;
        response.s = s;

        return response;
    }

    function decodeSignature(bytes memory signature) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    function encodeJSON(EIP155 memory txn) internal pure returns (bytes memory) {
        // encode transaction in json
        bytes memory txnEncoded;

        // dynamic fields
        if (txn.data.length != 0) {
            txnEncoded = abi.encodePacked(txnEncoded, '"input":"', LibString.toHexString(txn.data), '",');
        } else {
            txnEncoded = abi.encodePacked(txnEncoded, '"input":"0x",');
        }
        if (txn.to != address(0)) {
            txnEncoded = abi.encodePacked(txnEncoded, '"to":"', LibString.toHexString(txn.to), '",');
        } else {
            txnEncoded = abi.encodePacked(txnEncoded, '"to":null,');
        }

        // fixed fields
        txnEncoded = abi.encodePacked(
            txnEncoded,
            '"gas":"',
            LibString.toMinimalHexString(txn.gas),
            '","gasPrice":"',
            LibString.toMinimalHexString(txn.gasPrice),
            '","nonce":"',
            LibString.toMinimalHexString(txn.nonce),
            '","value":"',
            LibString.toMinimalHexString(txn.value),
            '","chainId":"',
            LibString.toMinimalHexString(txn.chainId),
            '","r":"',
            LibString.toHexString(abi.encodePacked(txn.r)),
            '","s":"',
            LibString.toHexString(abi.encodePacked(txn.s)),
            '",'
        );

        txnEncoded = abi.encodePacked(txnEncoded, '"v":"', LibString.toMinimalHexString(txn.v), '"');
        txnEncoded = abi.encodePacked("{", txnEncoded, "}");

        return txnEncoded;
    }
}
