// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../suavelib/Suave.sol";
import "../utils/HexStrings.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/JSONParserLib.sol";

/// @notice Bundle is a library with utilities to interact with the Flashbots bundle API described in https://docs.flashbots.net/flashbots-auction/advanced/rpc-endpoint#eth_sendbundle
library Bundle {
    /// @notice BundleObj is a struct that represents a bundle to be sent to the Flashbots relay.
    /// @param blockNumber the block number at which the bundle should be executed.
    /// @param txns the transactions to be included in the bundle.
    /// @param minTimestamp the minimum timestamp at which the bundle should be executed.
    /// @param maxTimestamp the maximum timestamp at which the bundle should be executed.
    /// @param revertingHashes the hashes of the transactions that the bundle should allow to revert.
    /// @param replacementUuid the UUID of the bundle submission that should be replaced by this bundle. This argument must have been passed to the bundle being replaced.
    /// @param refundPercent (mev-share) percentage of gas fees that should be refunded to the tx originator.
    struct BundleObj {
        uint64 blockNumber;
        bytes[] txns;
        // sendBundle exclusive:
        uint64 minTimestamp;
        uint64 maxTimestamp;
        bytes32[] revertingHashes;
        string replacementUuid;
        // SBundle (sim) exclusive
        uint256 refundPercent;
    }

    using JSONParserLib for string;
    using JSONParserLib for JSONParserLib.Item;
    using LibString for *;

    /// @notice send a bundle to the Flashbots relay.
    /// @param bundle the bundle to send.
    /// @param url the URL of the Flashbots relay.
    /// @return response raw bytes response from the Flashbots relay.
    function sendBundle(
        BundleObj memory bundle,
        string memory url
    ) internal returns (bytes memory) {
        Suave.HttpRequest memory request = encodeSendBundle(bundle);
        request.url = url;
        return Suave.doHTTPRequest(request);
    }

    /// @notice simulate a bundle using the Flashbots bundle API.
    /// @param bundle the bundle to simulate.
    /// @return egp the simulated effective gas price of the bundle.
    function simulateBundle(
        BundleObj memory bundle
    ) internal returns (uint64 egp) {
        bytes memory simParams = encodeSimBundle(bundle);
        egp = Suave.simulateBundle(simParams);
    }

    /// @notice Encodes an [RpcSBundle](https://github.com/flashbots/suave-geth/blob/main/core/types/sbundle.go#L21-L27) for `Suave.simulateBundle`.
    /// @param args the bundle to encode.
    /// @return params the encoded simulateBundle payload.
    function encodeSimBundle(
        BundleObj memory args
    ) internal pure returns (bytes memory params) {
        require(args.txns.length > 0, "Bundle: no txns");

        params = abi.encodePacked(
            '{"blockNumber": "',
            args.blockNumber.toMinimalHexString(),
            '", '
        );
        if (args.refundPercent > 0) {
            params = abi.encodePacked(
                params,
                '"percent": ',
                args.refundPercent.toString(),
                ", "
            );
        }
        if (args.revertingHashes.length > 0) {
            params = abi.encodePacked(params, '"revertingHashes": [');
            for (uint256 i = 0; i < args.revertingHashes.length; i++) {
                params = abi.encodePacked(
                    params,
                    '"',
                    uint256(args.revertingHashes[i]).toHexString(),
                    '"'
                );
                if (i < args.revertingHashes.length - 1) {
                    params = abi.encodePacked(params, ", ");
                }
            }
            params = abi.encodePacked(params, "], ");
        }
        params = abi.encodePacked(params, '"txs": [');
        for (uint256 i = 0; i < args.txns.length; i++) {
            params = abi.encodePacked(
                params,
                '"',
                args.txns[i].toHexString(),
                '"'
            );
            if (i < args.txns.length - 1) {
                params = abi.encodePacked(params, ", ");
            }
        }
        params = abi.encodePacked(params, "]}");
    }

    /// @notice Encodes a bundle into an RPC request to `eth_sendBundle`.
    /// @param args the bundle to encode.
    /// @return request the encoded HTTP request.
    function encodeSendBundle(
        BundleObj memory args
    ) internal pure returns (Suave.HttpRequest memory) {
        require(args.txns.length > 0, "Bundle: no txns");

        // body
        bytes memory body = abi.encodePacked(
            '{"jsonrpc": "2.0", "method": "eth_sendBundle", "id": 1, "params": [{'
        );

        // params
        body = abi.encodePacked(
            body,
            '"blockNumber": "',
            args.blockNumber.toMinimalHexString(),
            '", '
        );
        if (args.minTimestamp > 0) {
            body = abi.encodePacked(
                body,
                '"minTimestamp": ',
                args.minTimestamp.toString(),
                ", "
            );
        }
        if (args.maxTimestamp > 0) {
            body = abi.encodePacked(
                body,
                '"maxTimestamp": ',
                args.maxTimestamp.toString(),
                ", "
            );
        }
        if (args.revertingHashes.length > 0) {
            body = abi.encodePacked(body, '"revertingHashes": [');
            for (uint256 i = 0; i < args.revertingHashes.length; i++) {
                body = abi.encodePacked(
                    body,
                    '"',
                    abi.encodePacked(args.revertingHashes[i]),
                    '"'
                );
                if (i < args.revertingHashes.length - 1) {
                    body = abi.encodePacked(body, ", ");
                }
            }
            body = abi.encodePacked(body, "], ");
        }
        if (abi.encodePacked(args.replacementUuid).length > 0) {
            body = abi.encodePacked(
                body,
                '"replacementUuid": "',
                args.replacementUuid,
                '", '
            );
        }
        body = abi.encodePacked(body, '"txs": [');
        for (uint256 i = 0; i < args.txns.length; i++) {
            body = abi.encodePacked(body, '"', args.txns[i].toHexString(), '"');
            if (i < args.txns.length - 1) {
                body = abi.encodePacked(body, ", ");
            }
        }
        body = abi.encodePacked(body, "]}]}");

        Suave.HttpRequest memory request;
        request.method = "POST";
        request.body = abi.encodePacked(body);
        request.headers = new string[](1);
        request.headers[0] = "Content-Type: application/json";
        request.withFlashbotsSignature = true;

        return request;
    }

    function _stripQuotesAndPrefix(
        string memory s
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(s);
        bytes memory result = new bytes(strBytes.length - 4);
        for (uint256 i = 3; i < strBytes.length - 1; i++) {
            result[i - 3] = strBytes[i];
        }
        return string(result);
    }

    /// @notice decode a bundle from a JSON string.
    /// @param bundleJson the JSON string of the bundle.
    /// @return bundle the decoded bundle.
    function decodeBundle(
        string memory bundleJson
    ) public pure returns (Bundle.BundleObj memory) {
        JSONParserLib.Item memory root = bundleJson.parse();
        JSONParserLib.Item memory txnsNode = root.at('"txs"');
        Bundle.BundleObj memory bundle;
        require(txnsNode.isArray(), "Bundle: txs is not an array");
        uint256 txnsLength = txnsNode.size();
        bytes[] memory txns = new bytes[](txnsLength);

        for (uint256 i = 0; i < txnsLength; i++) {
            JSONParserLib.Item memory txnNode = txnsNode.at(i);
            bytes memory txn = HexStrings.fromHexString(
                _stripQuotesAndPrefix(txnNode.value())
            );
            txns[i] = txn;
        }
        bundle.txns = txns;

        require(
            root.at('"blockNumber"').isString(),
            "Bundle: blockNumber is not a string"
        );
        bundle.blockNumber = uint64(
            root.at('"blockNumber"').value().decodeString().parseUintFromHex()
        );

        if (root.at('"minTimestamp"').isNumber()) {
            bundle.minTimestamp = uint64(
                root.at('"minTimestamp"').value().parseUint()
            );
        }

        if (root.at('"maxTimestamp"').isNumber()) {
            bundle.maxTimestamp = uint64(
                root.at('"maxTimestamp"').value().parseUint()
            );
        }

        bundle.txns = txns;
        return bundle;
    }
}
