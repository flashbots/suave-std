// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Test.sol";
import "src/utils/Misc.sol";

contract MiscTest is Test {
    function x(uint256 n) public pure returns (uint256) {
        return n;
    }

    function testStripSelector() public pure {
        bytes memory suaveCalldata = abi.encodeWithSelector(this.x.selector, 123);
        bytes memory strippedCalldata = Misc.stripSelector(suaveCalldata);
        assertEq(strippedCalldata.length, 32);
        uint256 num = abi.decode(strippedCalldata, (uint256));
        assertEq(num, 123);
    }
}
