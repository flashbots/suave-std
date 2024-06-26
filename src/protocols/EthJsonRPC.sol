// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../suavelib/Suave.sol";
import "solady/src/utils/JSONParserLib.sol";
import "solady/src/utils/LibString.sol";
import "forge-std/console.sol";
import "../utils/HexStrings.sol";

/// @notice EthJsonRPC is a library with utilities to interact with an Ethereum JSON-RPC endpoint.
contract EthJsonRPC {
    using JSONParserLib for *;

    string endpoint;

    struct AccountOverride {
        address addr;
        bytes code;
    }

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

    /// @notice get the balance of an address.
    /// @param addr the address to get the balance.
    /// @return val the balance of the address.
    function balance(address addr) public returns (uint256) {
        bytes memory body = abi.encodePacked(
            '{"jsonrpc":"2.0","method":"eth_getBalance","params":["',
            LibString.toHexStringChecksummed(addr),
            '","latest"],"id":1}'
        );

        JSONParserLib.Item memory item = doRequest(string(body));
        uint256 val = JSONParserLib.parseUintFromHex(trimQuotes(item.value()));
        return val;
    }

    /// @notice call a contract function.
    /// @param to the address of the contract.
    /// @param data the data of the function.
    /// @return the result of the function call.
    function call(address to, bytes memory data) public returns (bytes memory) {
        bytes memory body = abi.encodePacked(
            '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"',
            LibString.toHexStringChecksummed(to),
            '","data":"',
            LibString.toHexString(data),
            '"},"latest"],"id":1}'
        );

        JSONParserLib.Item memory item = doRequest(string(body));
        bytes memory result = HexStrings.fromHexString(_stripQuotesAndPrefix(item.value()));
        return result;
    }

    /// @notice call a contract function with a state override.
    /// @param to the address of the contract.
    /// @param data the data of the function.
    /// @param accountOverride the state override.
    /// @return the result of the function call.
    function call(address to, bytes memory data, AccountOverride[] memory accountOverride)
        public
        returns (bytes memory)
    {
        bytes memory body = abi.encodePacked(
            '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"',
            LibString.toHexStringChecksummed(to),
            '","data":"',
            LibString.toHexString(data),
            '"},"latest",{'
        );

        for (uint256 i = 0; i < accountOverride.length; i++) {
            body = abi.encodePacked(
                body,
                '"',
                LibString.toHexStringChecksummed(accountOverride[i].addr),
                '": {"code": "',
                LibString.toHexString(accountOverride[i].code),
                '"}'
            );
            if (i < accountOverride.length - 1) {
                body = abi.encodePacked(body, ",");
            }
        }
        body = abi.encodePacked(body, '}],"id":1}');

        JSONParserLib.Item memory item = doRequest(string(body));
        bytes memory result = HexStrings.fromHexString(_stripQuotesAndPrefix(item.value()));

        return result;
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
        JSONParserLib.Item memory err = item.at('"error"');
        if (!err.isUndefined()) {
            revert(err.value());
        }
        return item.at('"result"');
    }

    function _stripQuotesAndPrefix(string memory s) internal pure returns (string memory) {
        bytes memory strBytes = bytes(s);
        bytes memory result = new bytes(strBytes.length - 4);
        for (uint256 i = 3; i < strBytes.length - 1; i++) {
            result[i - 3] = strBytes[i];
        }
        return string(result);
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
