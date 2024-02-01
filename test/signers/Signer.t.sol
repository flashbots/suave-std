// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Transactions.sol";
import "src/suavelib/Suave.sol";
import "src/Test.sol";

contract TestSigner is Test, SuaveEnabled {
    using Transactions for *;

    function signTxn(Transactions.EIP1559Request memory request, string memory signingKey)
        public
        view
        returns (Transactions.EIP1559 memory response)
    {
        bytes memory rlp = Transactions.encodeRLP(request);
        bytes memory hash = abi.encodePacked(keccak256(rlp));
        bytes memory signature = Suave.signMessage(hash, signingKey);

        // overflow
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

    function signTxn(Transactions.EIP155Request memory request, string memory signingKey)
        public
        view
        returns (Transactions.EIP155 memory response)
    {
        bytes memory rlp = Transactions.encodeRLP(request);
        bytes memory hash = abi.encodePacked(keccak256(rlp));
        bytes memory signature = Suave.signMessage(hash, signingKey);

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

    function testSignDynamicFeeTxn() public {
        string memory signingKey = "b71c71a67e1177ad4e901695e1b4b9ee17ae16c6668d313eac2f96dbcda3f291";

        Transactions.EIP1559Request memory txnrequest = Transactions.EIP1559Request({
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
            accessList: bytes("")
        });

        Transactions.EIP1559 memory response = signTxn(txnrequest, signingKey);

        bytes memory expected = abi.encodePacked(
            hex"02f89d012685114f11efdc85114f11efdc82fce88080b844a9059cbb00000000000000000000000061b7b515c1ec603cf21463bcac992b60fd610ca900000000000000000000000000000000000000000000002dbf877cf6ec677800c080a08d0e4df55c09f64ff0d9045e6073084e286f81a7b8f86c2829b7aedc653ed848a04941300e3b702e148dc37ded36119285623b939599c0345d2ed0634ec0cd40eb"
        );
        bytes memory rlp = Transactions.encodeRLP(response);
        assertEq0(rlp, expected);
    }

    function testSignEIP155Txn() public {
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

        Transactions.EIP155 memory txn = signTxn(txnWithToAddress, signingKey);

        bytes memory expected = abi.encodePacked(
            hex"f864018201f4830f42409400000000000000000000000000000000deadbeef0180820a95a0eebcfac0def6db5649d0ae6b52ed3b8ba1f5c6c428588df125461113ba8c6749a05d5e1aafa0c964b43c251b6a525d49572968f2cebc5868c58bcc9281b9a07505"
        );
        bytes memory rlp = Transactions.encodeRLP(txn);

        assertEq0(rlp, expected);
    }
}
