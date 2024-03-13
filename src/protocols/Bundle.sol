// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../suavelib/Suave.sol";
import "../utils/HexStrings.sol";
import "../utils/JsonWriter.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/JSONParserLib.sol";

// https://docs.flashbots.net/flashbots-auction/advanced/rpc-endpoint#eth_sendbundle
library Bundle {
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
    using JsonWriter for JsonWriter.Json;
    using LibString for *;

    function sendBundle(BundleObj memory bundle, string memory url) internal returns (bytes memory) {
        Suave.HttpRequest memory request = encodeSendBundle(bundle);
        request.url = url;
        return Suave.doHTTPRequest(request);
    }

    function simulateBundle(BundleObj memory bundle) internal returns (uint64 egp) {
        bytes memory simParams = encodeSimBundle(bundle);
        egp = Suave.simulateBundle(simParams);
    }

    /**
     * Encodes an [RpcSBundle](https://github.com/flashbots/suave-geth/blob/main/core/types/sbundle.go#L21-L27)
     * for `Suave.simulateBundle`.
     */
    function encodeSimBundle(BundleObj memory args) internal pure returns (bytes memory params) {
        require(args.txns.length > 0, "Bundle: no txns");
        JsonWriter.Json memory writer;

        writer = writer.writeStartObject();
        writer = writer.writeStringProperty("blockNumber", args.blockNumber.toHexString());
        if (args.refundPercent > 0) {
            writer = writer.writeUintProperty("percent", args.refundPercent);
        }
        if (args.revertingHashes.length > 0) {
            writer = writer.writeStartArray("revertingHashes");
            for (uint256 i = 0; i < args.revertingHashes.length; i++) {
                writer = writer.writeStringValue(uint256(args.revertingHashes[i]).toHexString());
            }
            writer = writer.writeEndArray();
        }
        writer = writer.writeStartArray("txs");
        for (uint256 i = 0; i < args.txns.length; i++) {
            writer = writer.writeStringValue(args.txns[i].toHexString());
        }
        writer = writer.writeEndArray();
        writer = writer.writeEndObject();

        params = abi.encodePacked(writer.value);
    }

    /**
     * Encodes a bundle into an RPC request to `eth_sendBundle`.
     */
    function encodeSendBundle(BundleObj memory args) internal pure returns (Suave.HttpRequest memory) {
        require(args.txns.length > 0, "Bundle: no txns");

        JsonWriter.Json memory writer;
        // body
        writer = writer.writeStartObject();
        writer = writer.writeStringProperty("jsonrpc", "2.0");
        writer = writer.writeStringProperty("method", "eth_sendBundle");
        writer = writer.writeUintProperty("id", 1);

        // params
        writer = writer.writeStartArray("params");
        writer = writer.writeStartObject();
        writer = writer.writeStringProperty("blockNumber", args.blockNumber.toHexString());
        writer = writer.writeStartArray("txs");
        for (uint256 i = 0; i < args.txns.length; i++) {
            writer = writer.writeStringValue(args.txns[i].toHexString());
        }
        writer = writer.writeEndArray();
        if (args.minTimestamp > 0) {
            writer = writer.writeUintProperty("minTimestamp", args.minTimestamp);
        }
        if (args.maxTimestamp > 0) {
            writer = writer.writeUintProperty("maxTimestamp", args.maxTimestamp);
        }
        if (args.revertingHashes.length > 0) {
            writer = writer.writeStartArray("revertingHashes");
            for (uint256 i = 0; i < args.revertingHashes.length; i++) {
                writer = writer.writeBytesValue(abi.encodePacked(args.revertingHashes[i]));
            }
            writer = writer.writeEndArray();
        }
        if (abi.encodePacked(args.replacementUuid).length > 0) {
            writer = writer.writeStringProperty("replacementUuid", args.replacementUuid);
        }
        writer = writer.writeEndObject();
        writer = writer.writeEndArray();
        writer = writer.writeEndObject();

        Suave.HttpRequest memory request;
        request.method = "POST";
        request.body = abi.encodePacked(writer.value);
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
