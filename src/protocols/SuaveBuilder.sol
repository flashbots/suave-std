// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../suavelib/Suave.sol";
import "../Transactions.sol";
import "solady/src/utils/LibString.sol";

library Encoder {
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
    function encodeBuildBlockArgs(BuildBlockArgs memory args) internal returns (bytes memory) {
        bytes memory body = abi.encodePacked(
            '{"slot":',
            LibString.toHexString(args.slot),
            ',"proposerPubkey":"',
            LibString.toHexString(args.proposerPubkey),
            '"',
            ',"parent":"',
            LibString.fromSmallString(args.parent),
            '"',
            ',"timestamp":',
            LibString.toHexString(args.timestamp)
        );

        body = abi.encodePacked(
            body,
            ',"feeRecipient":"',
            LibString.toHexStringChecksummed(args.feeRecipient),
            '"',
            ',"gasLimit":',
            LibString.toHexString(args.gasLimit),
            ',"random":"',
            LibString.fromSmallString(args.random),
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
            LibString.fromSmallString(args.beaconRoot),
            '"',
            ',"fillPending":',
            args.fillPending ? "true" : "false",
            "}"
        );
        return body;
    }

    // encodeWithdrawals encodes Withdrawal array to json
    function encodeWithdrawals(Withdrawal[] memory withdrawals) internal returns (bytes memory) {
        bytes memory result = abi.encodePacked("[");
        for (uint64 i = 0; i < withdrawals.length; i++) {
            result = abi.encodePacked(result, i > 0 ? "," : "", encodeWithdrawal(withdrawals[i]));
        }
        return abi.encodePacked(result, "]");
    }

    // encodeWithdrawal encodes Withdrawal to json
    function encodeWithdrawal(Withdrawal memory withdrawal) internal returns (bytes memory) {
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
}
