// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "src/forge/ConfidentialStore.sol";
import {SuaveEnabled} from "src/Test.sol";
import "forge-std/console2.sol";
import {ConfStore, ConfRecord, ConfKVS} from "src/ConfKVS.sol";

contract TestConfKVS is Test, SuaveEnabled {
    using ConfKVS for ConfStore;
    using ConfKVS for ConfRecord;

    // example initialization of ConfStore; allows any address to peek and store
    address[] public addressList = [Suave.ANYALLOWED];
    ConfStore cs = ConfStore(addressList, addressList, "my_app_name");

    /// set a confidential value and retrieve it, make sure the retrieved value matches what we set
    function testSimpleConfStore() public {
        string memory secretValue = "hello, suave!";
        ConfRecord memory cr = cs.set("secretMessage", abi.encodePacked(secretValue));

        bytes memory value = cr.get();
        assertEq(keccak256(value), keccak256(abi.encodePacked(secretValue)));
    }
}
