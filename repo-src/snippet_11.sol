// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Inherit the stdCheats
contract StdCheatsTest is Test {
    Bar test;
    function setUp() public {
        test = new Bar();
    }

    function testHoax() public {
        // we call `hoax`, which gives the target address
        // eth and then calls `prank`
        hoax(address(1337));
        test.bar{value: 100}(address(1337));

        // overloaded to allow you to specify how much eth to
        // initialize the address with
        hoax(address(1337), 1);
        test.bar{value: 1}(address(1337));
    }

    function testStartHoax() public {
        // we call `startHoax`, which gives the target address
        // eth and then calls `startPrank`
        //
        // it is also overloaded so that you can specify an eth amount
        startHoax(address(1337));
        test.bar{value: 100}(address(1337));
        test.bar{value: 100}(address(1337));
        vm.stopPrank();
        test.bar(address(this));
    }
}

contract Bar {
    function bar(address expectedSender) public payable {
        require(msg.sender == expectedSender, "!prank");
    }
}
