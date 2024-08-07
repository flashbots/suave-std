// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Types} from "src/protocols/Builder/Types.sol";
import "src/suavelib/Suave.sol";
import "../../Fixtures.sol";

contract SuaveBuilderTypesTest is Test {
    function testSuaveBuilderTypes_Encode_BuildblockArgs() public view {
        Types.BuildBlockArgs memory args;
        args.slot = 1;
        args.proposerPubkey = hex"1234";
        args.parent = hex"5678";
        args.timestamp = 123;
        args.feeRecipient = address(0x1234);
        args.gasLimit = 123;
        args.random = hex"1234";
        args.extra = hex"1234";
        args.beaconRoot = hex"1234";
        args.fillPending = true;
        bytes memory encode = Types.encodeBuildBlockArgs(args);
        Fixtures.validate("suave_builder_builderArgs.json", string(encode));
    }

    function testSuaveBuilderTypes_Decode_SimulateTransactionResult() public view {
        string memory test = Fixtures.readFixture("suave_builder_simulateTransactionResult_failed.json");
        Types.SimulateTransactionResult memory result = Types.decodeSimulateTransactionResult(test);
        assertEq(result.success, false);
        assertEq(result.error, "some error");

        test = Fixtures.readFixture("suave_builder_simulateTransactionResult_success.json");
        result = Types.decodeSimulateTransactionResult(test);
        assertEq(result.success, true);
        assertEq(result.logs.length, 1);
        assertEq(result.logs[0].addr, address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
        assertEq(result.logs[0].data, hex"00000000000000000000000000000000000000000000000000000000000004d2");
        assertEq(result.logs[0].topics.length, 1);
        assertEq(result.logs[0].topics[0], bytes32(0x379340f64b65a8890c7ea4f6d86d2359beaf41080f36a7ea64b78a2c06eee3f0));
    }
}
