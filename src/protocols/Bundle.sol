// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../suavelib/Suave.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/JSONParserLib.sol";

// https://docs.flashbots.net/flashbots-auction/advanced/rpc-endpoint#eth_sendbundle
library Bundle {
    struct BundleObj {
        string url;
        uint64 blockNumber;
        uint64 minTimestamp;
        uint64 maxTimestamp;
        bytes[] txns;
    }

    function sendBundle(string memory url, Bundle memory bundle) internal view {
        Suave.HttpRequest memory request = encodeBundle(bundle);
        request.url = url;
        Suave.doHTTPRequest(request);
    }

    function encodeBundle(BundleObj memory args) internal pure returns (Suave.HttpRequest memory) {
        bytes memory params = abi.encodePacked("{", '"txs": [', txn, "],", '"blockNumber": "', args.blockNumber, '"}');
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
}
