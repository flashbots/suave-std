// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./Logs.sol";

contract Suapp {
    modifier emitOffchainLogs() {
        Logs.decodeLogs(msg.data);
        _;
    }
}
