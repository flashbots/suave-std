// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./Wrapper2.sol";

contract SuaveEnabled {
    function setUp() public {
        Suave2.enable();
    }
}
