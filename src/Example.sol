// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract XX {
    struct HelloStruct {
        string a;
        string[] b;
        uint256 c;
    }

    function encode(HelloStruct memory obj) internal pure returns (bytes memory) {
        bytes memory body;
        body = abi.encodePacked(body, '{"hello":', obj.a, ',"world": "normal","vals": [');
        for (uint64 i = 0; i < obj.b.length; i++) {
            body = abi.encodePacked(body, obj.b[i]);
            if (i != obj.b.length - 1) body = abi.encodePacked(body, ",");
        }
        body = abi.encodePacked(body, "]");
        if (obj.c != 0) body = abi.encodePacked(body, ',"test":', obj.c);
        body = abi.encodePacked(body, "}");
        return body;
    }
}
