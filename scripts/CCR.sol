// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CCRForgeUtil} from "../src/forge/CCR.sol";

contract CCR is Script {
    function run() public {
        uint256 privateKeyUserSuave =
            uint256(bytes32(0x6c45335a22461ccdb978b78ab61b238bad2fae4544fb55c14eb096c875ccfc52));
        uint256 forkIdSuave = vm.createFork("http://localhost:8545");
        vm.selectFork(forkIdSuave);

        //vm.startBroadcast(privateKeyUserSuave);
        DummySuapp suapp = new DummySuapp();

        //vm.stopBroadcast();

        bytes memory targetCall = abi.encodeWithSignature("dummyFunction()");

        // send the CCR request
        CCRForgeUtil ccrUtil = new CCRForgeUtil();
        ccrUtil.createAndSendCCR({
            signingPrivateKey: privateKeyUserSuave,
            confidentialInputs: abi.encode(""),
            targetCall: targetCall,
            nonce: 1,
            to: 0x000C002053b3197c5a4ec8ab73fb7C48c35B1980,
            gas: 10000000,
            gasPrice: 1000000000,
            value: 0,
            executionNode: 0xB5fEAfbDD752ad52Afb7e1bD2E40432A485bBB7F,
            chainId: uint256(0x01008C45)
        });
    }
}

contract DummySuapp {
    function callback() public {}

    function dummyFunction() public pure returns (bytes memory) {
        return abi.encodeWithSelector(this.callback.selector);
    }
}
