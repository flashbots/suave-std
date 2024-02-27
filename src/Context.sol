// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./suavelib/Suave.sol";

library Context {
    function confidentialInputs() internal returns (bytes memory) {
        return Suave.contextGet("confidentialInputs");
    }

    function kettleAddress() internal returns (address) {
        bytes memory _bytes = Suave.contextGet("kettleAddress");

        address addr;
        assembly {
            addr := mload(add(_bytes, 20))
        }

        return addr;
    }
}
