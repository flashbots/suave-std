// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./suavelib/Suave.sol";

/// @notice Context is a library with functions to retrieve the context of the MEVM execution.
library Context {
    /// @notice returns the confidential inputs of the confidential compute request.
    /// @return output bytes of the confidential inputs.
    function confidentialInputs() internal returns (bytes memory) {
        return Suave.contextGet("confidentialInputs");
    }

    /// @notice returns the address of the Kettle that executes the confidential compute request.
    /// @return kettleAddress address of the kettle.
    function kettleAddress() internal returns (address) {
        bytes memory _bytes = Suave.contextGet("kettleAddress");

        address addr;
        assembly {
            addr := mload(add(_bytes, 20))
        }

        return addr;
    }
}
