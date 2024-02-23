// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../suavelib/Suave.sol";
import "../utils/JsonWriter.sol";
import "./Bundle.sol";
import "solady/src/utils/LibString.sol";

library Suavex {
    using JsonWriter for JsonWriter.Json;
    using LibString for *;

    function buildEthBlock(string memory url, Suave.BuildBlockArgs memory args, Bundle.BundleObj[] memory bundles)
        public
        returns (bytes memory)
    {
        string memory params = encodeBuildEthBlock(args, bundles);
        bytes memory body = encodeRpcRequest("suavex_buildEthBlockFromBundles", params, 1);
        Suave.HttpRequest memory request;
        request.url = url;
        request.method = "POST";
        request.body = body;
        request.headers = new string[](1);
        request.headers[0] = "Content-Type: application/json";
        request.withFlashbotsSignature = true;
        return Suave.doHTTPRequest(request);
    }

    function encodeBuildEthBlock(Suave.BuildBlockArgs memory args, Bundle.BundleObj[] memory bundles)
        internal
        pure
        returns (string memory)
    {
        JsonWriter.Json memory writer;

        writer = writer.writeStartObject();

        // args
        writer = writer.writeStartObject("args");

        writer = writer.writeUintProperty("slot", args.slot);
        writer = writer.writeBytesProperty("proposerPubkey", args.proposerPubkey);
        writer = writer.writeStringProperty("parent", abi.encodePacked(args.parent).toHexString());
        writer = writer.writeUintProperty("timestamp", args.timestamp);
        writer = writer.writeAddressProperty("feeRecipient", args.feeRecipient);
        writer = writer.writeUintProperty("gasLimit", args.gasLimit);
        writer = writer.writeStringProperty("random", abi.encodePacked(args.random).toHexString());

        // args - withdrawals
        writer = writer.writeStartArray("withdrawals");
        for (uint256 i = 0; i < args.withdrawals.length; i++) {
            writer = writer.writeStartObject();
            writer = writer.writeStringProperty("index", args.withdrawals[i].index.toHexString());
            writer = writer.writeStringProperty("validator", args.withdrawals[i].validator.toHexString());
            writer = writer.writeAddressProperty("address", args.withdrawals[i].Address);
            writer = writer.writeStringProperty("amount", args.withdrawals[i].amount.toHexString());
            writer = writer.writeEndObject();
        }
        writer = writer.writeEndArray();

        writer = writer.writeBytesProperty("extra", args.extra);
        writer = writer.writeBytesProperty("beaconRoot", abi.encodePacked(args.beaconRoot));
        writer = writer.writeBooleanProperty("fillPending", args.fillPending);

        writer = writer.writeEndObject();

        // bundles
        writer = writer.writeStartArray("bundles");

        for (uint256 i = 0; i < bundles.length; i++) {
            writer = writer.writeStartObject();
            writer = writer.writeStringProperty("blockNumber", bundles[i].blockNumber.toHexString());
            writer = writer.writeStringProperty("minTimestamp", bundles[i].minTimestamp.toHexString());
            writer = writer.writeStringProperty("maxTimestamp", bundles[i].maxTimestamp.toHexString());

            writer = writer.writeStartArray("txs");
            for (uint256 j = 0; j < bundles[i].txns.length; j++) {
                writer = writer.writeStringValue(bundles[i].txns[j].toHexString());
            }
            writer = writer.writeEndArray();
            writer = writer.writeEndObject();
        }
        writer = writer.writeEndArray();
        writer = writer.writeEndObject();
        return writer.value;
    }

    function encodeRpcRequest(string memory method, string memory params, uint256 id) internal pure returns (bytes memory) {
        return abi.encodePacked('{"jsonrpc":"2.0","method":"', method, '","params":[', params, '],"id":', LibString.toString(id), '}');
    }
}
