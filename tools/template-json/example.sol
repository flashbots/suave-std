// SPDX-License-Identifier: UNLICENSED
// DO NOT edit this file. Code generated by forge-gen.
pragma solidity ^0.8.8;

import "solady/src/utils/LibString.sol";

library BundleEncoder {
    struct Bundle {
        string a;
    }

    function encode(Bundle memory obj0) internal pure returns (bytes memory) {
        bytes memory body;
        body = abi.encodePacked(body, '{   "hello":', obj.obj0, "}");
        return body;
    }
}

