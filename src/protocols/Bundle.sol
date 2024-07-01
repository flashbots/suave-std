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
    /// @param minTimestamp the minimum timestamp at which the bundle should be executed.
    /// @param maxTimestamp the maximum timestamp at which the bundle should be executed.
    /// @param txns the transactions to be included in the bundle.
    struct BundleObj {
        uint64 blockNumber;
        uint64 minTimestamp;
        uint64 maxTimestamp;
        bytes[] txns;
    }

    using JSONParserLib for string;
    using JSONParserLib for JSONParserLib.Item;

    /// @notice send a bundle to the Flashbots relay.
    /// @param url the URL of the Flashbots relay.
    /// @param bundle the bundle to send.
    /// @return response raw bytes response from the Flashbots relay.
    function sendBundle(string memory url, BundleObj memory bundle) internal returns (bytes memory) {
        Suave.HttpRequest memory request = encodeBundle(bundle);
        request.url = url;
        return Suave.doHTTPRequest(request);
    }

    /// @notice encode a bundle in json format.
    /// @param args the bundle to encode.
    /// @return params JSON-encoded bytes: `{blockNumber, txs, minTimestamp, maxTimestamp}`
    function encodeBundleParams(BundleObj memory args) internal pure returns (bytes memory params) {
        params = abi.encodePacked('{"blockNumber": "', LibString.toMinimalHexString(args.blockNumber), '", "txs": [');
        for (uint256 i = 0; i < args.txns.length; i++) {
            params = abi.encodePacked(params, '"', LibString.toHexString(args.txns[i]), '"');
            if (i < args.txns.length - 1) {
                params = abi.encodePacked(params, ",");
            } else {
                params = abi.encodePacked(params, "]");
            }
        }
        if (args.minTimestamp > 0) {
            params = abi.encodePacked(params, ', "minTimestamp": ', LibString.toString(args.minTimestamp));
        }
        if (args.maxTimestamp > 0) {
            params = abi.encodePacked(params, ', "maxTimestamp": ', LibString.toString(args.maxTimestamp));
        }
        params = abi.encodePacked(params, "}");
    }

    /// @notice encode a call to `eth_sendBundle` as an HttpRequest.
    /// @param args the bundle to encode.
    /// @return request the HttpRequest to send the bundle.
    function encodeBundle(BundleObj memory args) internal pure returns (Suave.HttpRequest memory) {
        require(args.txns.length > 0, "Bundle: no txns");

        bytes memory params = encodeBundleParams(args);
        bytes memory body =
            abi.encodePacked('{"jsonrpc":"2.0","method":"eth_sendBundle","params":[', params, '],"id":1}');

        Suave.HttpRequest memory request;
        request.method = "POST";
        request.body = body;
        request.headers = new string[](1);
        request.headers[0] = "Content-Type: application/json";
        request.withFlashbotsSignature = true;

        return request;
    }

    function _stripQuotesAndPrefix(string memory s) internal pure returns (string memory) {
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
    function decodeBundle(string memory bundleJson) public pure returns (Bundle.BundleObj memory) {
        JSONParserLib.Item memory root = bundleJson.parse();
        JSONParserLib.Item memory txnsNode = root.at('"txs"');
        Bundle.BundleObj memory bundle;
        require(txnsNode.isArray(), "Bundle: txs is not an array");
        uint256 txnsLength = txnsNode.size();
        bytes[] memory txns = new bytes[](txnsLength);

        for (uint256 i = 0; i < txnsLength; i++) {
            JSONParserLib.Item memory txnNode = txnsNode.at(i);
            bytes memory txn = HexStrings.fromHexString(_stripQuotesAndPrefix(txnNode.value()));
            txns[i] = txn;
        }
        bundle.txns = txns;

        require(root.at('"blockNumber"').isString(), "Bundle: blockNumber is not a string");
        bundle.blockNumber = uint64(root.at('"blockNumber"').value().decodeString().parseUintFromHex());

        if (root.at('"minTimestamp"').isNumber()) {
            bundle.minTimestamp = uint64(root.at('"minTimestamp"').value().parseUint());
        }

        if (root.at('"maxTimestamp"').isNumber()) {
            bundle.maxTimestamp = uint64(root.at('"maxTimestamp"').value().parseUint());
        }

        bundle.txns = txns;
        return bundle;
    }
}
