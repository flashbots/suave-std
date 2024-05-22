// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

abstract contract ObservableOrderflow {
    event SentBundle(bytes32 bundleHash);
    event SentBundle(bytes32 bundleHash, bytes32[] txHashes);
    event SentTransaction(bytes32 txHash);
    event SentTransactions(bytes32[] txHashes);
}
