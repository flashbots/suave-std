// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/protocols/Suavex.sol";
import "src/suavelib/Suave.sol";
import "solady/src/utils/JSONParserLib.sol";

contract SuavexTest is Test {
    using JSONParserLib for string;

    function testEncodeBuildEthBlockFromBundles() public {
        Bundle.BundleObj memory bundle;
        bundle.blockNumber = 1;
        bundle.minTimestamp = 2;
        bundle.maxTimestamp = 3;
        bundle.txns = new bytes[](1);
        bundle.txns[0] = hex"1234";

        Suave.BuildBlockArgs memory args;

        args.slot = 1;
        args.proposerPubkey = hex"1234";
        args.parent = hex"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        args.timestamp = 1;
        args.feeRecipient = address(0);
        args.gasLimit = 1;
        args.random = hex"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
        args.withdrawals = new Suave.Withdrawal[](1);

        Suave.Withdrawal memory withdrawal;
        withdrawal.index = 1;
        withdrawal.validator = 1;
        withdrawal.Address = address(0);
        withdrawal.amount = 1238912748128;

        args.withdrawals[0] = withdrawal;

        args.extra = hex"1234";
        args.beaconRoot = hex"cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";
        args.fillPending = false;

        Bundle.BundleObj[] memory bundles = new Bundle.BundleObj[](1);
        bundles[0] = bundle;
        string memory result = Suavex.encodeBuildEthBlockFromBundles(args, bundles);
        assertEq(result, '{"args": {"slot": 1,"proposerPubkey": "EjQ=","parent": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","timestamp": 1,"feeRecipient": "0x0000000000000000000000000000000000000000","gasLimit": 1,"random": "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","withdrawals": [{"index": "0x01","validator": "0x01","address": "0x0000000000000000000000000000000000000000","amount": "0x012074f44a60"}],"extra": "EjQ=","beaconRoot": "zMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMw=","fillPending": false},"bundles": [{"blockNumber": "0x01","minTimestamp": "0x02","maxTimestamp": "0x03","txs": ["0x1234"]}]}');
    }

    function testEncodeCall() public {
        address contractAddr = address(0);
        bytes memory input = abi.encodeWithSignature("someMethod(uint256,string,address)", 1, "hello", address(1));
        string memory result = Suavex.encodeCall(contractAddr, input);
        assertEq(result, '{"contractAddr": "0x0000000000000000000000000000000000000000","input": "NS8NrQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFaGVsbG8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC="}');
    }
}
