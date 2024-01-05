// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./utils/RLPWriter.sol";
import "Solidity-RLP/RLPReader.sol";

library Transactions {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    struct Legacy {
        address to;
        uint64 gas;
        uint64 gasPrice;
        uint64 value;
        uint64 nonce;
        bytes data;
        uint64 chainId;
        bytes r;
        bytes s;
        bytes v;
    }

    struct EIP1559 {
        address to;
        uint64 gas;
        uint64 maxFeePerGas;
        uint64 maxPriorityFeePerGas;
        uint64 value;
        uint64 nonce;
        bytes data;
        uint64 chainId;
        bytes[] accessList;
        bytes r;
        bytes s;
        bytes v;
    }

    function encodeLegacyRLP(Legacy memory txStruct) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](9);

        items[0] = RLPWriter.writeUint(txStruct.nonce);
        items[1] = RLPWriter.writeUint(txStruct.gasPrice);
        items[2] = RLPWriter.writeUint(txStruct.gas);
        items[3] = RLPWriter.writeAddress(txStruct.to);
        items[4] = RLPWriter.writeUint(txStruct.value);
        items[5] = RLPWriter.writeBytes(txStruct.data);
        items[6] = RLPWriter.writeBytes(txStruct.v);
        items[7] = RLPWriter.writeBytes(txStruct.r);
        items[8] = RLPWriter.writeBytes(txStruct.s);

        return RLPWriter.writeList(items);
    }

    function encodeRLP(EIP1559 memory txStruct) internal pure returns (bytes memory) {
        bytes[] memory items = new bytes[](12);

        items[0] = RLPWriter.writeUint(txStruct.chainId);
        items[1] = RLPWriter.writeUint(txStruct.nonce);
        items[2] = RLPWriter.writeUint(txStruct.maxPriorityFeePerGas);
        items[3] = RLPWriter.writeUint(txStruct.maxFeePerGas);
        items[4] = RLPWriter.writeUint(txStruct.gas);
        items[5] = RLPWriter.writeAddress(txStruct.to);
        items[6] = RLPWriter.writeUint(txStruct.value);
        items[7] = RLPWriter.writeBytes(txStruct.data);
        items[8] = RLPWriter.writeList(txStruct.accessList);
        items[9] = RLPWriter.writeBytes(txStruct.v);
        items[10] = RLPWriter.writeBytes(txStruct.r);
        items[11] = RLPWriter.writeBytes(txStruct.s);

        return RLPWriter.writeList(items);
    }

    function decodeLegacyRLP(bytes memory rlp) internal pure returns (Legacy memory) {
        Legacy memory txStruct;

        RLPReader.RLPItem[] memory ls = rlp.toRlpItem().toList();
        require(ls.length == 9, "invalid transaction");

        txStruct.nonce = uint64(ls[0].toUint());
        txStruct.gasPrice = uint64(ls[1].toUint());
        txStruct.gas = uint64(ls[2].toUint());
        txStruct.to = ls[3].toAddress();
        txStruct.value = uint64(ls[4].toUint());
        txStruct.data = ls[5].toBytes();
        txStruct.v = ls[6].toBytes();
        txStruct.r = ls[7].toBytes();
        txStruct.s = ls[8].toBytes();

        return txStruct;
    }

    function decodeRLP(bytes memory rlp) internal pure returns (EIP1559 memory) {
        EIP1559 memory txStruct;

        RLPReader.RLPItem[] memory ls = rlp.toRlpItem().toList();
        require(ls.length == 12, "invalid transaction");

        txStruct.chainId = uint64(ls[0].toUint());
        txStruct.nonce = uint64(ls[1].toUint());
        txStruct.maxPriorityFeePerGas = uint64(ls[2].toUint());
        txStruct.maxFeePerGas = uint64(ls[3].toUint());
        txStruct.gas = uint64(ls[4].toUint());
        txStruct.to = ls[5].toAddress();
        txStruct.value = uint64(ls[6].toUint());
        txStruct.data = ls[7].toBytes();

        // Decode accessList
        RLPReader.RLPItem[] memory accessListItems = ls[8].toBytes().toRlpItem().toList();
        uint256 numAccessListItems = accessListItems.length;
        txStruct.accessList = new bytes[](numAccessListItems);

        for (uint256 i; i < numAccessListItems; i++) {
            txStruct.accessList[i] = accessListItems[i].toBytes();
        }

        txStruct.v = ls[9].toBytes();
        txStruct.r = ls[10].toBytes();
        txStruct.s = ls[11].toBytes();

        return txStruct;
    }
}
