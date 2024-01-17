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
    }

    function encodeRLP(
        Legacy memory txStruct
    ) internal pure returns (bytes memory) {
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

    function decodeRLP(bytes memory rlp) internal pure returns (Legacy memory) {
        Legacy memory txStruct;

        RLPReader.RLPItem[] memory ls = rlp.toRlpItem().toList();
        require(ls.length == 9, "invalid transaction");

        txStruct.nonce = uint64(ls[0].toUint());
        txStruct.gasPrice = uint64(ls[1].toUint());
        txStruct.gas = uint64(ls[2].toUint());

        if (ls[3].toRlpBytes().length == 1) {
            txStruct.to = address(0);
        } else {
            txStruct.to = ls[3].toAddress();
        }

        txStruct.value = uint64(ls[4].toUint());
        txStruct.data = ls[5].toBytes();
        txStruct.chainId = uint64(ls[6].toUint());

        return txStruct;
    }
}
