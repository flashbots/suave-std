// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import "src/suavelib/Suave.sol";
import "src/Test.sol";

contract TestRandom is Test, SuaveEnabled {
    function testRandomBytes() public {
        bytes memory random = Suave.randomBytes(32);
        console2.logBytes(random);
        assert(random.length == 32);
    }

    function testRandomUint256() public {
        uint256 random = Suave.randomUint256();
        console2.log("random uint256: %d", random);
        assert(random > 0);
    }
}
