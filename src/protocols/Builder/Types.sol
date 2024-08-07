// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../../suavelib/Suave.sol";
import "../../Transactions.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/JSONParserLib.sol";

library Types {
    using JSONParserLib for *;

    struct SimulateTransactionResult {
        uint64 egp;
        SimulatedLog[] logs;
        bool success;
        string error;
    }

    struct SimulatedLog {
        bytes data;
        address addr;
        bytes32[] topics;
    }

    struct BuildBlockArgs {
        uint64 slot;
        bytes proposerPubkey;
        bytes32 parent;
        uint64 timestamp;
        address feeRecipient;
        uint64 gasLimit;
        bytes32 random;
        Withdrawal[] withdrawals;
        bytes extra;
        bytes32 beaconRoot;
        bool fillPending;
    }

    struct Withdrawal {
        uint64 index;
        uint64 validator;
        address Address;
        uint64 amount;
    }

    // encodeBuildBlockArgs encodes BuildBlockArgs to json
    function encodeBuildBlockArgs(BuildBlockArgs memory args) internal pure returns (bytes memory) {
        bytes memory body = abi.encodePacked(
            '{"slot":"',
            LibString.toMinimalHexString(args.slot),
            '","proposerPubkey":"',
            LibString.toHexString(args.proposerPubkey),
            '"',
            ',"parent":"',
            LibString.toHexString(abi.encodePacked(args.parent)),
            '"',
            ',"timestamp":"',
            LibString.toHexString(args.timestamp)
        );

        body = abi.encodePacked(
            body,
            '","feeRecipient":"',
            LibString.toHexStringChecksummed(args.feeRecipient),
            '"',
            ',"gasLimit":"',
            LibString.toHexString(args.gasLimit),
            '","random":"',
            LibString.toHexString(abi.encodePacked(args.random)),
            '"'
        );

        body = abi.encodePacked(
            body,
            ',"withdrawals":',
            encodeWithdrawals(args.withdrawals),
            ',"extra":"',
            LibString.toHexString(args.extra),
            '"',
            ',"beaconRoot":"',
            LibString.toHexString(abi.encodePacked(args.beaconRoot)),
            '"',
            ',"fillPending":',
            args.fillPending ? "true" : "false",
            "}"
        );
        return body;
    }

    // encodeWithdrawals encodes Withdrawal array to json
    function encodeWithdrawals(Withdrawal[] memory withdrawals) internal pure returns (bytes memory) {
        bytes memory result = abi.encodePacked("[");
        for (uint64 i = 0; i < withdrawals.length; i++) {
            result = abi.encodePacked(result, i > 0 ? "," : "", encodeWithdrawal(withdrawals[i]));
        }
        return abi.encodePacked(result, "]");
    }

    // encodeWithdrawal encodes Withdrawal to json
    function encodeWithdrawal(Withdrawal memory withdrawal) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '{"index":',
            LibString.toHexString(withdrawal.index),
            ',"validator":',
            LibString.toHexString(withdrawal.validator),
            ',"Address":"',
            LibString.toHexStringChecksummed(withdrawal.Address),
            '"',
            ',"amount":',
            LibString.toHexString(withdrawal.amount),
            "}"
        );
    }

    function decodeSimulateTransactionResult(string memory input)
        internal
        pure
        returns (SimulateTransactionResult memory result)
    {
        JSONParserLib.Item memory item = input.parse();
        return decodeSimulateTransactionResult(item);
    }

    function decodeSimulatedLog(JSONParserLib.Item memory item) internal pure returns (SimulatedLog memory log) {
        log.data = fromHexString(_stripQuotesAndPrefix(item.at('"data"').value()));
        log.addr = bytesToAddress(fromHexString(_stripQuotesAndPrefix(item.at('"addr"').value())));

        JSONParserLib.Item[] memory topics = item.at('"topics"').children();
        log.topics = new bytes32[](topics.length);
        for (uint64 i = 0; i < topics.length; i++) {
            log.topics[i] = bytesToBytes32(fromHexString(_stripQuotesAndPrefix(topics[i].value())));
        }
    }

    function decodeSimulateTransactionResult(JSONParserLib.Item memory item)
        internal
        pure
        returns (SimulateTransactionResult memory result)
    {
        if (compareStrings(item.at('"success"').value(), "true")) {
            result.success = true;
        } else {
            result.success = false;
            result.error = trimQuotes(item.at('"error"').value());
        }

        // decode logs
        JSONParserLib.Item[] memory logs = item.at('"logs"').children();
        result.logs = new SimulatedLog[](logs.length);
        for (uint64 i = 0; i < logs.length; i++) {
            result.logs[i] = decodeSimulatedLog(logs[i]);
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        // Check if the lengths of the strings are the same
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            // Compare each character of the strings
            for (uint256 i = 0; i < bytes(a).length; i++) {
                if (bytes(a)[i] != bytes(b)[i]) {
                    return false;
                }
            }
            return true;
        }
    }

    function trimQuotes(string memory input) private pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        require(
            inputBytes.length >= 2 && inputBytes[0] == '"' && inputBytes[inputBytes.length - 1] == '"', "Invalid input"
        );

        bytes memory result = new bytes(inputBytes.length - 2);

        for (uint256 i = 1; i < inputBytes.length - 1; i++) {
            result[i - 1] = inputBytes[i];
        }

        return string(result);
    }

    function _fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
        revert("fail");
    }

    function _stripQuotesAndPrefix(string memory s) internal pure returns (string memory) {
        bytes memory strBytes = bytes(s);
        bytes memory result = new bytes(strBytes.length - 4);
        for (uint256 i = 3; i < strBytes.length - 1; i++) {
            result[i - 3] = strBytes[i];
        }
        return string(result);
    }

    // Convert an hexadecimal string to raw bytes
    function fromHexString(string memory s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0); // length must be even
        bytes memory r = new bytes(ss.length / 2);
        for (uint256 i = 0; i < ss.length / 2; ++i) {
            r[i] = bytes1(_fromHexChar(uint8(ss[2 * i])) * 16 + _fromHexChar(uint8(ss[2 * i + 1])));
        }
        return r;
    }

    function bytesToAddress(bytes memory data) public pure returns (address) {
        // Ensure data length is at least 20 bytes (address length)
        require(data.length >= 20, "Invalid data length");

        address addr;
        // Convert bytes to address
        assembly {
            addr := mload(add(data, 20))
        }
        return addr;
    }

    function bytesToBytes32(bytes memory data) public pure returns (bytes32) {
        require(data.length >= 32, "Data length must be at least 32 bytes");

        bytes32 result;
        assembly {
            // Copy 32 bytes from data to result
            result := mload(add(data, 32))
        }
        return result;
    }
}
