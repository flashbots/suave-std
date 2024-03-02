// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./suavelib/Suave.sol";

library Random {
    function randomUint8() internal returns (uint8 value) {
        bytes memory random = Suave.randomBytes(1);
        assembly {
            value := mload(add(random, 0x01))
        }
    }

    function randomUint16() internal returns (uint16 value) {
        bytes memory random = Suave.randomBytes(2);
        assembly {
            value := mload(add(random, 0x02))
        }
    }

    function randomUint32() internal returns (uint32 value) {
        bytes memory random = Suave.randomBytes(4);
        assembly {
            value := mload(add(random, 0x04))
        }
    }

    function randomUint64() internal returns (uint64 value) {
        bytes memory random = Suave.randomBytes(8);
        assembly {
            value := mload(add(random, 0x08))
        }
    }

    function randomUint128() internal returns (uint128 value) {
        bytes memory random = Suave.randomBytes(16);
        assembly {
            value := mload(add(random, 0x10))
        }
    }

    function randomUint256() internal returns (uint256 value) {
        bytes memory random = Suave.randomBytes(32);
        assembly {
            value := mload(add(random, 0x20))
        }
    }
}
