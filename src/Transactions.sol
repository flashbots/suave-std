// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./utils/RLPWriter.sol";
import "Solidity-RLP/RLPReader.sol";

library Transactions {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    // LegacyTransaction is rlp([nonce, gasPrice, gasLimit, to, value, data, v, r, s])
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

    // rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list, signature_y_parity, signature_r, signature_s])
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

    function encodeRLP(Legacy memory txStruct) internal pure returns (bytes memory) {
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

        bytes[] memory accessListEncoded = new bytes[](txStruct.accessList.length);
        for (uint256 i; i < txStruct.accessList.length; i++) {
            accessListEncoded[i] = RLPWriter.writeBytes(abi.encodePacked(txStruct.accessList[i]));
        }
        items[8] = RLPWriter.writeList(accessListEncoded);

        items[9] = RLPWriter.writeBytes(txStruct.v);
        items[10] = RLPWriter.writeBytes(txStruct.r);
        items[11] = RLPWriter.writeBytes(txStruct.s);

        return RLPWriter.writeList(items);
    }

    function decodeRLP(bytes memory rlp) internal pure returns (Legacy memory) {
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
}
