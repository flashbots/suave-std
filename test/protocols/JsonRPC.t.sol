// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Test.sol";
import "solady/src/utils/LibString.sol";
import "src/protocols/JsonRPC.sol";

contract JsonRPCTest is Test, SuaveEnabled {
    function testJsonRPCGetNonce() public {
        JsonRPC jsonrpc = getJsonRPC();

        uint256 nonce = jsonrpc.nonce(address(this));
        assertEq(nonce, 0);
    }

    function getJsonRPC() public returns (JsonRPC jsonrpc) {
        try vm.envString("JSONRPC_ENDPOINT") returns (string memory endpoint) {
            jsonrpc = new JsonRPC(endpoint);
        } catch {
            vm.skip(true);
        }
    }
}
