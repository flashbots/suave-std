// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Test.sol";
import "src/suavelib/Suave.sol";

contract TestForge is Test, SuaveEnabled {
    address[] public addressList = [0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829];

    function testConfidentialStore() public {
        Suave.DataRecord memory record = Suave.newDataRecord(0, addressList, addressList, "namespace");

        bytes memory value = abi.encode("suave works with forge!");
        Suave.confidentialStore(record.id, "key1", value);

        bytes memory found = Suave.confidentialRetrieve(record.id, "key1");
        assertEq(keccak256(found), keccak256(value));
    }

    function testConfidentialReset() public {
        Suave.DataRecord memory record = Suave.newDataRecord(0, addressList, addressList, "namespace");

        bytes memory value = abi.encode("suave works with forge!");
        Suave.confidentialStore(record.id, "key1", value);

        bytes memory found = Suave.confidentialRetrieve(record.id, "key1");
        console.logBytes(found);

        resetConfidentialStore();

        bytes memory found2 = Suave.confidentialRetrieve(record.id, "key1");
        assertEq(found2.length, 0);
    }
}
