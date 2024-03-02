// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import "src/suavelib/Suave.sol";
import "src/Random.sol";
import "src/Test.sol";

contract TestRandom is Test, SuaveEnabled {
    function testRandomBytes() public {
        bytes memory random = Suave.randomBytes(32);
        console2.logBytes(random);
        assert(random.length == 32);
    }

    function testRandomUint8() public {
        uint8 random = Random.randomUint8();
        console2.log("random uint8: %d", random);
        assert(random > 0);
    }

    function testRandomUint16() public {
        uint16 random = Random.randomUint16();
        console2.log("random uint16: %d", random);
        assert(random > 0);
    }

    function testRandomUint32() public {
        uint32 random = Random.randomUint32();
        console2.log("random uint32: %d", random);
        assert(random > 0);
    }

    function testRandomUint64() public {
        uint64 random = Random.randomUint64();
        console2.log("random uint64: %d", random);
        assert(random > 0);
    }

    function testRandomUint128() public {
        uint128 random = Random.randomUint128();
        console2.log("random uint128: %d", random);
        assert(random > 0);
    }

    function testRandomUint256() public {
        uint256 random = Random.randomUint256();
        console2.log("random uint256: %d", random);
        assert(random > 0);
    }
}
