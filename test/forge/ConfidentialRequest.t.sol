// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Test.sol";
import {ConfRequest, Status} from "src/forge/ConfidentialRequest.sol";
import {NumberSuapp} from "../Forge.t.sol";

contract ConfRequestTest is Test, SuaveEnabled {
    using ConfRequest for address;

    NumberSuapp numberSuapp = new NumberSuapp();

    function testConfRequest() public {
        ctx.setConfidentialInputs(abi.encode(0x42));
        (Status s,) = address(numberSuapp).sendConfRequest(abi.encodeWithSelector(NumberSuapp.setNumber.selector));
        assertEq(uint256(s), uint256(Status.SUCCESS));
        assertEq(numberSuapp.number(), 0x42);
    }
}
