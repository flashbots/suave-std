// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Misc {
    /**
     * @notice Returns the given bytes with the first 4 bytes removed.
     */
    function stripSelector(bytes memory data) internal pure returns (bytes memory trimmedData) {
        trimmedData = new bytes(data.length - 4);
        assembly {
            mstore(add(trimmedData, 0x20), sub(mload(add(data, 0x20)), 0x04))
            mstore(add(trimmedData, 0x20), mload(add(data, 0x24)))
        }
    }
}
