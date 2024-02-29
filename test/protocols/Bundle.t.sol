// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/protocols/Bundle.sol";
import "../../src/suavelib/Suave.sol";

contract EthSendBundle is Test {
    function testEthSendBundleEncode() public {
        Bundle.BundleObj memory bundle;
        bundle.blockNumber = 1;
        bundle.txns = new bytes[](1);
        bundle.txns[0] = hex"1234";

        Suave.HttpRequest memory request = Bundle.encodeBundle(bundle);
        assertEq(
            string(request.body),
            '{"jsonrpc":"2.0","method":"eth_sendBundle","params":[{"blockNumber": "0x01", "txs": ["0x1234"]}],"id":1}'
        );
        assertTrue(request.withFlashbotsSignature);

        // encode with 'minTimestamp'
        bundle.minTimestamp = 2;

        Suave.HttpRequest memory request2 = Bundle.encodeBundle(bundle);
        assertEq(
            string(request2.body),
            '{"jsonrpc":"2.0","method":"eth_sendBundle","params":[{"blockNumber": "0x01", "txs": ["0x1234"], "minTimestamp": 2}],"id":1}'
        );

        // encode with 'maxTimestamp'
        bundle.maxTimestamp = 3;

        Suave.HttpRequest memory request3 = Bundle.encodeBundle(bundle);
        assertEq(
            string(request3.body),
            '{"jsonrpc":"2.0","method":"eth_sendBundle","params":[{"blockNumber": "0x01", "txs": ["0x1234"], "minTimestamp": 2, "maxTimestamp": 3}],"id":1}'
        );
    }

    function testSimBundleParams() public {
        Bundle.BundleObj memory bundle;
        bundle.blockNumber = 1;
        bundle.txns = new bytes[](1);
        bundle.txns[0] = hex"1234";
        bundle.refundPercent = 50;

        bytes memory params = Bundle.simParams(bundle);
        assertEq(string(params), '{"blockNumber": "0x01", "refundPercent": 50, "txs": ["0x1234"]}');

        // encode with 'revertingHashes'
        bundle.revertingHashes = new bytes32[](1);
        bundle.revertingHashes[0] = keccak256("hashem");

        bytes memory params2 = Bundle.simParams(bundle);
        assertEq(
            string(params2),
            '{"blockNumber": "0x01", "refundPercent": 50, "revertingHashes": ["0x0a80df9c7574c9524999e774c05a27acf214618b45f4948b88ad1083e13a871a"], "txs": ["0x1234"]}'
        );
    }
}
