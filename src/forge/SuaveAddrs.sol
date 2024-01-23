// SPDX-License-Identifier: UNLICENSED
// DO NOT edit this file. Code generated by forge-gen.
pragma solidity ^0.8.8;

import "../suavelib/Suave.sol";

library SuaveAddrs {
    function getSuaveAddrs() external pure returns (address[] memory) {
        address[] memory addrList = new address[](17);

        addrList[0] = Suave.IS_CONFIDENTIAL_ADDR;
        addrList[1] = Suave.BUILD_ETH_BLOCK;
        addrList[2] = Suave.CONFIDENTIAL_RETRIEVE;
        addrList[3] = Suave.CONFIDENTIAL_STORE;
        addrList[4] = Suave.DO_HTTPREQUEST;
        addrList[5] = Suave.ETHCALL;
        addrList[6] = Suave.EXTRACT_HINT;
        addrList[7] = Suave.FETCH_DATA_RECORDS;
        addrList[8] = Suave.FILL_MEV_SHARE_BUNDLE;
        addrList[9] = Suave.NEW_BUILDER;
        addrList[10] = Suave.NEW_DATA_RECORD;
        addrList[11] = Suave.SIGN_ETH_TRANSACTION;
        addrList[12] = Suave.SIGN_MESSAGE;
        addrList[13] = Suave.SIMULATE_BUNDLE;
        addrList[14] = Suave.SIMULATE_TRANSACTION;
        addrList[15] = Suave.SUBMIT_BUNDLE_JSON_RPC;
        addrList[16] = Suave.SUBMIT_ETH_BLOCK_TO_RELAY;

        return addrList;
    }
}
