// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Send confidential requests in Forge.
library ConfRequest {
    /// Sends a confidential request; calls offchain function and onchain callback.
    function sendConfRequest(address to, bytes memory data) internal returns (Status, bytes memory callbackResult) {
        // offchain execution
        (bool success, bytes memory suaveCalldata) = to.call(data);
        if (!success) {
            return (Status.FAILURE_OFFCHAIN, suaveCalldata);
        }
        suaveCalldata = abi.decode(suaveCalldata, (bytes));
        // onchain callback
        (success, callbackResult) = to.call(suaveCalldata);
        if (!success) {
            return (Status.FAILURE_ONCHAIN, callbackResult);
        }
        return (Status.SUCCESS, callbackResult);
    }
}

enum Status {
    SUCCESS,
    FAILURE_OFFCHAIN,
    FAILURE_ONCHAIN
}
