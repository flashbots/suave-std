// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./suavelib/Suave.sol";

/// @notice Random is a library with utilities to generate random data.
library Random {
    /// @notice generate a random uint8 number.
    /// @return value is the random number
    function randomUint8() internal returns (uint8 value) {
        bytes memory random = Suave.randomBytes(1);
        assembly {
            value := mload(add(random, 0x01))
        }
    }

    /// @notice generate a random uint16 number.
    /// @return value is the random number
    function randomUint16() internal returns (uint16 value) {
        bytes memory random = Suave.randomBytes(2);
        assembly {
            value := mload(add(random, 0x02))
        }
    }

    /// @notice generate a random uint32 number.
    /// @return value is the random number
    function randomUint32() public returns (uint32 value) {
        bytes memory random = Suave.randomBytes(4);
        assembly {
            value := mload(add(random, 0x04))
        }
    }

    /// @notice generate a random uint64 number.
    /// @return value is the random number
    function randomUint64() internal returns (uint64 value) {
        bytes memory random = Suave.randomBytes(8);
        assembly {
            value := mload(add(random, 0x08))
        }
    }

    /// @notice generate a random uint128 number.
    /// @return value is the random number
    function randomUint128() internal returns (uint128 value) {
        bytes memory random = Suave.randomBytes(16);
        assembly {
            value := mload(add(random, 0x10))
        }
    }

    /// @notice generate a random uint256 number.
    /// @return value is the random number
    function randomUint256() internal returns (uint256 value) {
        bytes memory random = Suave.randomBytes(32);
        assembly {
            value := mload(add(random, 0x20))
        }
    }
}
