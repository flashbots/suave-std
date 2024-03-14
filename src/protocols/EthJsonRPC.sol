// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "src/suavelib/Suave.sol";
import "solady/src/utils/JSONParserLib.sol";
import "solady/src/utils/LibString.sol";

/// @notice EthJsonRPC is a library with utilities to interact with an Ethereum JSON-RPC endpoint.
contract EthJsonRPC {
    using JSONParserLib for *;

    string endpoint;

    constructor(string memory _endpoint) {
        endpoint = _endpoint;
    }

    /// @notice get the nonce of an address.
    /// @param addr the address to get the nonce.
    /// @return val the nonce of the address.
    function nonce(address addr) public returns (uint256) {
        bytes memory body = abi.encodePacked(
            '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["',
            LibString.toHexStringChecksummed(addr),
            '","latest"],"id":1}'
        );

        JSONParserLib.Item memory item = doRequest(string(body));
        uint256 val = JSONParserLib.parseUintFromHex(trimQuotes(item.value()));
        return val;
    }

    function doRequest(string memory body) public returns (JSONParserLib.Item memory) {
        Suave.HttpRequest memory request;
        request.method = "POST";
        request.url = endpoint;
        request.headers = new string[](1);
        request.headers[0] = "Content-Type: application/json";
        request.body = bytes(body);

        bytes memory output = Suave.doHTTPRequest(request);

        JSONParserLib.Item memory item = string(output).parse();
        return item.at('"result"');
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
}
