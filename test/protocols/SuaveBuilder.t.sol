// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Encoder} from "src/protocols/SuaveBuilder.sol";
import "src/suavelib/Suave.sol";

contract SuaveBuilderTest is Test {
    function testSuaveBuilder_Encode_BuildblockArgs() public {
        Encoder.BuildBlockArgs memory args;
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
        bytes memory example = Encoder.encodeBuildBlockArgs(args);
        console.log(string(example));
    }
}
