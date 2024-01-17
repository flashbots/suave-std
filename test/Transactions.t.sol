// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Transactions.sol";

contract TestTransactions is Test {
    using Transactions for *;

    function testLegacyTransactionRLPEncoding() public {
        Transactions.Legacy memory txnWithToAddress = Transactions.Legacy({
            to: address(0x095E7BAea6a6c7c4c2DfeB977eFac326aF552d87),
            gas: 50000,
            gasPrice: 10,
            value: 10,
            nonce: 0,
            data: bytes(""),
            chainId: 0
        });

        bytes memory expected = abi.encodePacked(
            hex"df800a82c35094095e7baea6a6c7c4c2dfeb977efac326af552d870a80808080"
        );
        _testLegacyTransaction(txnWithToAddress, expected);

        Transactions.Legacy memory txnWithoutToAddress = Transactions.Legacy({
            to: address(0),
            gas: 50000,
            gasPrice: 10,
            value: 10,
            nonce: 1,
            data: abi.encodePacked(hex"02"),
            chainId: 0
        });

        expected = abi.encodePacked(hex"cb010a82c350800a02808080");
        _testLegacyTransaction(txnWithoutToAddress, expected);
    }

    function _testLegacyTransaction(
        Transactions.Legacy memory legacyTxn,
        bytes memory expectedRlp
    ) public {
        bytes memory rlp = Transactions.encodeRLP(legacyTxn);
        assertEq0(rlp, expectedRlp);

        Transactions.Legacy memory legacyTxn1 = Transactions.decodeRLP(rlp);

        // re-encode to validate that the decoding was correct
        bytes memory rlp1 = Transactions.encodeRLP(legacyTxn1);
        assertEq0(rlp1, expectedRlp);
    }
}
