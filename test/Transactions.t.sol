// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Transactions.sol";

contract TestTransactions is Test {
    using Transactions for *;

    function testEIP155TransactionRLPEncoding() public {
        Transactions.EIP155 memory txnWithToAddress = Transactions.EIP155({
            to: address(0x095E7BAea6a6c7c4c2DfeB977eFac326aF552d87),
            gas: 50000,
            gasPrice: 10,
            value: 10,
            nonce: 0,
            data: bytes(""),
            chainId: 0,
            v: abi.encodePacked(hex"1b"),
            r: abi.encodePacked(hex"9bea4c4daac7c7c52e093e6a4c35dbbcf8856f1af7b059ba20253e70848d094f"),
            s: abi.encodePacked(hex"8a8fae537ce25ed8cb5af9adac3f141af69bd515bd2ba031522df09b97dd72b1")
        });

        bytes memory expected = abi.encodePacked(
            hex"f85f800a82c35094095e7baea6a6c7c4c2dfeb977efac326af552d870a801ba09bea4c4daac7c7c52e093e6a4c35dbbcf8856f1af7b059ba20253e70848d094fa08a8fae537ce25ed8cb5af9adac3f141af69bd515bd2ba031522df09b97dd72b1"
        );
        _testEIP155Transaction(txnWithToAddress, expected);

        Transactions.EIP155 memory txnWithoutToAddress = Transactions.EIP155({
            to: address(0),
            gas: 50000,
            gasPrice: 10,
            value: 10,
            nonce: 1,
            data: abi.encodePacked(hex"02"),
            chainId: 0,
            v: abi.encodePacked(hex"1b"),
            r: abi.encodePacked(hex"754a33a9c37cfcf61cd61939fd93f5fe194b7d1ee6ef07490e8c880f3bd0d87d"),
            s: abi.encodePacked(hex"715bd50fa2c24e2ce0ea595025a44a39ac238558882f9f07dd885ddc51839419")
        });

        expected = abi.encodePacked(
            hex"f84b010a82c350800a021ba0754a33a9c37cfcf61cd61939fd93f5fe194b7d1ee6ef07490e8c880f3bd0d87da0715bd50fa2c24e2ce0ea595025a44a39ac238558882f9f07dd885ddc51839419"
        );
        _testEIP155Transaction(txnWithoutToAddress, expected);
    }

    function testEIP1559TransactionRLPEncoding() public {
        Transactions.EIP1559 memory txnWithToAddress = Transactions.EIP1559({
            to: address(0xaea46A60368A7bD060eec7DF8CBa43b7EF41Ad85),
            gas: 64744,
            maxFeePerGas: 74341019612,
            maxPriorityFeePerGas: 74341019612,
            value: 0,
            nonce: 38,
            data: abi.encodePacked(
                hex"a9059cbb00000000000000000000000061b7b515c1ec603cf21463bcac992b60fd610ca900000000000000000000000000000000000000000000002dbf877cf6ec677800"
                ),
            chainId: 1,
            accessList: bytes(""),
            v: bytes(""),
            r: abi.encodePacked(hex"8ee28a85ac42174b9e10c49613c0cddcf5d5a5ecb90bd516f81b45a957a64fe2"),
            s: abi.encodePacked(hex"05349c1076cc83990f425773d6b5995474782f1fccf1b2e43529ac54ac6ae144")
        });

        bytes memory expected = abi.encodePacked(
            hex"02f8b1012685114f11efdc85114f11efdc82fce894aea46a60368a7bd060eec7df8cba43b7ef41ad8580b844a9059cbb00000000000000000000000061b7b515c1ec603cf21463bcac992b60fd610ca900000000000000000000000000000000000000000000002dbf877cf6ec677800c080a08ee28a85ac42174b9e10c49613c0cddcf5d5a5ecb90bd516f81b45a957a64fe2a005349c1076cc83990f425773d6b5995474782f1fccf1b2e43529ac54ac6ae144"
        );

        _testEIP1559Transaction(txnWithToAddress, expected);

        Transactions.EIP1559 memory txnWithoutToAddress = Transactions.EIP1559({
            to: address(0),
            gas: 64744,
            maxFeePerGas: 74341019612,
            maxPriorityFeePerGas: 74341019612,
            value: 0,
            nonce: 38,
            data: abi.encodePacked(
                hex"a9059cbb00000000000000000000000061b7b515c1ec603cf21463bcac992b60fd610ca900000000000000000000000000000000000000000000002dbf877cf6ec677800"
                ),
            chainId: 1,
            accessList: bytes(""),
            v: bytes(""),
            r: abi.encodePacked(hex"8ee28a85ac42174b9e10c49613c0cddcf5d5a5ecb90bd516f81b45a957a64fe2"),
            s: abi.encodePacked(hex"05349c1076cc83990f425773d6b5995474782f1fccf1b2e43529ac54ac6ae144")
        });

        expected = abi.encodePacked(
            hex"02f89d012685114f11efdc85114f11efdc82fce88080b844a9059cbb00000000000000000000000061b7b515c1ec603cf21463bcac992b60fd610ca900000000000000000000000000000000000000000000002dbf877cf6ec677800c080a08ee28a85ac42174b9e10c49613c0cddcf5d5a5ecb90bd516f81b45a957a64fe2a005349c1076cc83990f425773d6b5995474782f1fccf1b2e43529ac54ac6ae144"
        );

        _testEIP1559Transaction(txnWithoutToAddress, expected);
    }

    function _testEIP155Transaction(Transactions.EIP155 memory legacyTxn, bytes memory expectedRlp) public {
        bytes memory rlp = Transactions.encodeRLP(legacyTxn);
        assertEq0(rlp, expectedRlp);

        Transactions.EIP155 memory legacyTxn1 = Transactions.decodeRLP_EIP155(rlp);

        // re-encode to validate that the decoding was correct
        bytes memory rlp1 = Transactions.encodeRLP(legacyTxn1);
        assertEq0(rlp1, expectedRlp);
    }

    function _testEIP1559Transaction(Transactions.EIP1559 memory eip1559Txn, bytes memory expectedRlp) public {
        bytes memory rlp = Transactions.encodeRLP(eip1559Txn);
        assertEq0(rlp, expectedRlp);

        Transactions.EIP1559 memory eip1559Txn1 = Transactions.decodeRLP_EIP1559(rlp);

        // re-encode to validate that the decoding was correct
        bytes memory rlp1 = Transactions.encodeRLP(eip1559Txn1);
        assertEq0(rlp1, expectedRlp);
    }
}
