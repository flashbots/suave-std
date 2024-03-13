// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/protocols/Bundle.sol";
import "src/suavelib/Suave.sol";
import "solady/src/utils/LibString.sol";

contract EthSendBundle is Test {
    using LibString for *;

    function testEthSendBundleEncode() public {
        Bundle.BundleObj memory bundle;
        bundle.blockNumber = 1;
        bundle.txns = new bytes[](1);
        bundle.txns[0] = hex"1234";

        Suave.HttpRequest memory request = Bundle.encodeSendBundle(bundle);
        assertEq(
            string(request.body),
            '{"jsonrpc": "2.0","method": "eth_sendBundle","id": 1,"params": [{"blockNumber": "0x01","txs": ["0x1234"]}]}'
        );
        assertTrue(request.withFlashbotsSignature);

        // encode with 'minTimestamp'
        bundle.minTimestamp = 2;

        Suave.HttpRequest memory request2 = Bundle.encodeSendBundle(bundle);
        assertEq(
            string(request2.body),
            '{"jsonrpc": "2.0","method": "eth_sendBundle","id": 1,"params": [{"blockNumber": "0x01","txs": ["0x1234"],"minTimestamp": 2}]}'
        );

        // encode with 'maxTimestamp'
        bundle.maxTimestamp = 3;

        Suave.HttpRequest memory request3 = Bundle.encodeSendBundle(bundle);
        assertEq(
            string(request3.body),
            '{"jsonrpc": "2.0","method": "eth_sendBundle","id": 1,"params": [{"blockNumber": "0x01","txs": ["0x1234"],"minTimestamp": 2,"maxTimestamp": 3}]}'
        );
    }

    function testEncodeSimBundle() public {
        Bundle.BundleObj memory bundle;
        bundle.blockNumber = 1;
        bundle.txns = new bytes[](1);
        bundle.txns[0] = hex"1234";
        bundle.refundPercent = 50;

        bytes memory params = Bundle.encodeSimBundle(bundle);
        assertEq(string(params), '{"blockNumber": "0x01","percent": 50,"txs": ["0x1234"]}');

        // encode with 'revertingHashes'
        bundle.revertingHashes = new bytes32[](1);
        bundle.revertingHashes[0] = keccak256("hashem");

        bytes memory params2 = Bundle.encodeSimBundle(bundle);
        assertEq(
            string(params2),
            '{"blockNumber": "0x01","percent": 50,"revertingHashes": ["0x0a80df9c7574c9524999e774c05a27acf214618b45f4948b88ad1083e13a871a"],"txs": ["0x1234"]}'
        );
    }

    function testBundleDecode() public {
        string memory json = "{" '"blockNumber": "0xdead",' '"minTimestamp": 1625072400,'
            '"maxTimestamp": 1625076000,' '"txs": [' '"0xdeadbeef",' '"0xc0ffee",' '"0x00aabb"' "]" "}";

        Bundle.BundleObj memory bundle = Bundle.decodeBundle(json);
        assertEq(bundle.blockNumber, 0xdead);
        assertEq(bundle.minTimestamp, 1625072400);
        assertEq(bundle.maxTimestamp, 1625076000);
        assertEq(bundle.txns.length, 3);
        assertEq(bundle.txns[0].toHexString(), "0xdeadbeef");
        assertEq(bundle.txns[1].toHexString(), "0xc0ffee");
        assertEq(bundle.txns[2].toHexString(), "0x00aabb");
    }
}
