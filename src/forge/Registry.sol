// SPDX-License-Identifier: UNLICENSED
// DO NOT edit this file. Code generated by forge-gen.
pragma solidity ^0.8.8;

import "../suavelib/Suave.sol";
import "./Connector.sol";
import "./ConfidentialInputs.sol";

interface registryVM {
    function etch(address, bytes calldata) external;
}

library Registry {
    registryVM constant vm = registryVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function enableLib(address addr) public {
        // code for Forge proxy connector
        deployCode(addr, type(Connector).creationCode);
    }

    function enable() public {
        enableLib(Suave.IS_CONFIDENTIAL_ADDR);
        enableLib(Suave.BUILD_ETH_BLOCK);
        enableLib(Suave.CONFIDENTIAL_RETRIEVE);
        enableLib(Suave.CONFIDENTIAL_STORE);
        enableLib(Suave.DO_HTTPREQUEST);
        enableLib(Suave.ETHCALL);
        enableLib(Suave.EXTRACT_HINT);
        enableLib(Suave.FETCH_DATA_RECORDS);
        enableLib(Suave.FILL_MEV_SHARE_BUNDLE);
        enableLib(Suave.NEW_BUILDER);
        enableLib(Suave.NEW_DATA_RECORD);
        enableLib(Suave.SIGN_ETH_TRANSACTION);
        enableLib(Suave.SIGN_MESSAGE);
        enableLib(Suave.SIMULATE_BUNDLE);
        enableLib(Suave.SIMULATE_TRANSACTION);
        enableLib(Suave.SUBMIT_BUNDLE_JSON_RPC);
        enableLib(Suave.SUBMIT_ETH_BLOCK_TO_RELAY);

        // enable is confidential wrapper
        deployCode(Suave.CONFIDENTIAL_INPUTS, type(ConfidentialInputsWrapper).creationCode);
    }

    address constant dummyAddr = 0x1111000000000000000000000000000000000000;

    function deployCode(address where, bytes memory creationCode) internal {
        vm.etch(dummyAddr, creationCode);
        (, bytes memory runtimeBytecode) = dummyAddr.call("");

        vm.etch(where, runtimeBytecode);
    }
}
