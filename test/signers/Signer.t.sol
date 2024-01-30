// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Transactions.sol";
import "src/suavelib/Suave.sol";
import "src/Test.sol";

contract TestSigner is Test, SuaveEnabled {
    using Transactions for *;

    function testSignerXXX() public {
        string memory signingKey = "b71c71a67e1177ad4e901695e1b4b9ee17ae16c6668d313eac2f96dbcda3f291";

        Transactions.EIP155Request memory txnWithToAddress = Transactions.EIP155Request({
            to: address(0x00000000000000000000000000000000DeaDBeef),
            gas: 1000000,
            gasPrice: 500,
            value: 1,
            nonce: 1,
            data: bytes(""),
            chainId: 1337
        });

        bytes memory rlp = Transactions.encodeRLP(txnWithToAddress);
        console.logBytes(rlp);

        bytes memory hash = abi.encodePacked(keccak256(rlp));
        console.logBytes(hash);
        console.log(signingKey);

        bytes memory signature = Suave.signMessage(hash, signingKey);
        console.logBytes(signature);

        // overflow
        uint256 chainIdMul = txnWithToAddress.chainId * 2;
        (uint8 xxxx, bytes32 r, bytes32 s) = decodeSignature(signature);

        // since it has chain id
        uint256 v = uint256(uint8(signature[64])) + 35;
        v += chainIdMul;

        console.logString("-- signature values --");
        console.logUint(v);
        console.logBytes(abi.encodePacked(v));
        console.logBytes32(r);
        console.logBytes32(s);
    }
}
