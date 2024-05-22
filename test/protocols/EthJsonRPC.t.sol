// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Test.sol";
import "solady/src/utils/LibString.sol";
import "src/protocols/EthJsonRPC.sol";

contract EthJsonRPCTest is Test, SuaveEnabled {
    function testEthJsonRPCGetNonce() public {
        EthJsonRPC ethjsonrpc = getEthJsonRPC();

        uint256 nonce = ethjsonrpc.nonce(address(this));
        assertEq(nonce, 0);
    }

    function testEthJsonRPCGetBalance() public {
        EthJsonRPC ethjsonrpc = getEthJsonRPC();

        uint256 balance = ethjsonrpc.balance(address(this));
        assertEq(balance, 0);
    }

    function testEthJsonRPCCall() public {
        EthJsonRPC ethjsonrpc = getEthJsonRPC();

        bytes memory data = abi.encodeWithSignature("get_deposit_count()");
        bytes memory result = ethjsonrpc.call(address(0x00000000219ab540356cBB839Cbe05303d7705Fa), data);
        uint256 resultUint = abi.decode(result, (uint256));

        require(resultUint > 0, "result is empty");
    }

    function testEthJsonRPCCallWithOverrides() public {
        EthJsonRPC ethjsonrpc = getEthJsonRPC();

        EthJsonRPC.AccountOverride memory accountOverride = EthJsonRPC.AccountOverride({
            addr: address(0x00000000219ab540356cBB839Cbe05303d7705Fa),
            code: type(TestOverrideContract).runtimeCode
        });

        EthJsonRPC.AccountOverride[] memory acco = new EthJsonRPC.AccountOverride[](1);
        acco[0] = accountOverride;

        bytes memory data = abi.encodeWithSignature("get_deposit_count()");
        bytes memory result = ethjsonrpc.call(address(0x00000000219ab540356cBB839Cbe05303d7705Fa), data, acco);
        uint256 resultUint = abi.decode(result, (uint256));

        require(resultUint == 10, "result is empty");
    }

    function getEthJsonRPC() public returns (EthJsonRPC ethjsonrpc) {
        try vm.envString("JSONRPC_ENDPOINT") returns (string memory endpoint) {
            ethjsonrpc = new EthJsonRPC(endpoint);
        } catch {
            vm.skip(true);
        }
    }
}

contract TestOverrideContract {
    function get_deposit_count() public pure returns (uint256) {
        return 10;
    }
}
