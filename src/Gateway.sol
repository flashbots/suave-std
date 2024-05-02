// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./protocols/EthJsonRPC.sol";
import "forge-std/console.sol";

contract Gateway {
    EthJsonRPC ethjsonrpc;
    address target;

    constructor(string memory _jsonrpc, address _target) {
        ethjsonrpc = new EthJsonRPC(_jsonrpc);
        target = _target;
    }

    fallback() external {
        bytes memory ret = ethjsonrpc.call(target, msg.data);

        assembly {
            let location := ret
            let length := mload(ret)
            return(add(location, 0x20), length)
        }
    }
}
