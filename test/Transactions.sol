// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Transactions.sol";

contract TestTransactions is Test {
    using Transactions for *;

    function testLegacyTransactionRLPEncoding() public {
        Transactions.Legacy memory legacyTxn0 = Transactions.Legacy({
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

        bytes memory rlp = Transactions.encodeLegacyRLP(legacyTxn0);

        bytes memory expected = abi.encodePacked(
            hex"f85f800a82c35094095e7baea6a6c7c4c2dfeb977efac326af552d870a801ba09bea4c4daac7c7c52e093e6a4c35dbbcf8856f1af7b059ba20253e70848d094fa08a8fae537ce25ed8cb5af9adac3f141af69bd515bd2ba031522df09b97dd72b1"
        );
        assertEq0(rlp, expected);

        Transactions.Legacy memory legacyTxn1 = Transactions.decodeLegacyRLP(rlp);

        // re-encode to validate that the decoding was correct
        bytes memory rlp1 = Transactions.encodeLegacyRLP(legacyTxn1);
        assertEq0(rlp1, expected);
    }
}
