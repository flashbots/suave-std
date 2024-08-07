// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../suavelib/Suave.sol";
import "../../Transactions.sol";
import "solady/src/utils/LibString.sol";
import {Types} from "./Types.sol";
import "solady/src/utils/JSONParserLib.sol";
import "../../utils/HexStrings.sol";

contract Session is Test {
    using JSONParserLib for *;

    string url;
    string session;

    constructor(string memory _url) {
        url = _url;
    }

    function start(Types.BuildBlockArgs memory args) public {
        bytes memory encoded = Types.encodeBuildBlockArgs(args);
        JSONParserLib.Item memory output = callImpl("newSession", encoded);
        session = output.value();
    }

    function addTransaction(Transactions.EIP155 memory txn) public returns (Types.SimulateTransactionResult memory) {
        bytes memory encoded = Transactions.encodeJSON(txn);

        bytes memory input = abi.encodePacked(session, ",", encoded);
        JSONParserLib.Item memory output = callImpl("addTransaction", input);

        Types.SimulateTransactionResult memory result = Types.decodeSimulateTransactionResult(output.value());
        return result;
    }

    function buildBlock() public {
        bytes memory input = abi.encodePacked(session);
        callImpl("buildBlock", input);
    }

    function bid(string memory blsPubKey) public returns (JSONParserLib.Item memory output) {
        bytes memory input = abi.encodePacked(session, ',"0x', blsPubKey, '"');
        output = callImpl("bid", input);

        console.log("-- bid output --");
        console.log(output.value());

        // retrieve the root to sign
        bytes memory root = HexStrings.fromHexString(HexStrings.stripQuotesAndPrefix(output.at('"root"').value()));
        // TODO: do something with this root
        root; // suppress warning
    }

    function doCall(address target, bytes memory data) public returns (bytes memory) {
        bytes memory encodedRequest = abi.encodePacked(
            '{"to":"', LibString.toHexStringChecksummed(target), '","data":"', LibString.toHexString(data), '"}'
        );
        return doCall(encodedRequest);
    }

    function doCall(bytes memory encodedRequest) public returns (bytes memory) {
        bytes memory input = abi.encodePacked(session, ",", encodedRequest);
        JSONParserLib.Item memory item = callImpl("call", input);

        bytes memory result = HexStrings.fromHexString(HexStrings.stripQuotesAndPrefix(item.value()));
        return result;
    }

    function callImpl(string memory method, bytes memory args) internal returns (JSONParserLib.Item memory) {
        Suave.HttpRequest memory request;
        request.method = "POST";
        request.url = url;
        request.headers = new string[](1);
        request.headers[0] = "Content-Type: application/json";

        bytes memory body =
            abi.encodePacked('{"jsonrpc":"2.0","method":"suavex_', method, '","params":[', args, '],"id":1}');
        request.body = body;

        console.log(string(body));

        bytes memory output = Suave.doHTTPRequest(request);

        console.log(string(output));

        JSONParserLib.Item memory item = string(output).parse();
        return item.at('"result"');
    }
}
