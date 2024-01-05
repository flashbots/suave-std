// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./forge/Registry.sol";

contract SuaveEnabled {
    function setUp() public {
        // TODO: Add checks to validate that:
        // - User is running the test with ffi. Since vm.ffi is deployed as a contract, the error if ffi is not active
        // is reported as a Suave.PeekerReverted error and it is not clear what the problem is.
        // - Suave binary is on $PATH and Suave is running. This could be done with ffi calls to the suave binary.
        // Put this logic inside `enable` itself.
        Registry.enable();
    }
}
