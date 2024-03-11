// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./Logs.sol";

/// @notice Suapp is a contract with general utilities for a Suapp.
contract Suapp {
    /// @notice modifier to emit the offchain logs.
    modifier emitOffchainLogs() {
        Logs.decodeLogs(msg.data);
        _;
    }
}
