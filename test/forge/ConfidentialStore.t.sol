// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/forge/ConfidentialStore.sol";

contract TestConfidentialStore is Test {
    ConfidentialStore store;
    address[] public addressList = [0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829];

    function setUp() public {
        store = new ConfidentialStore();
    }

    function testConfidentialStoreNewRecordAndFetch() public {
        // This function tests that we can create new data records and fetch them
        store.newDataRecord(0, addressList, addressList, "namespace");
        store.newDataRecord(0, addressList, addressList, "namespace1");
        store.newDataRecord(1, addressList, addressList, "namespace");

        // fetch the records
        Suave.DataRecord[] memory records = store.fetchDataRecords(0, "namespace");
        assertEq(records.length, 1);

        records = store.fetchDataRecords(0, "namespace1");
        assertEq(records.length, 1);

        records = store.fetchDataRecords(1, "namespace");
        assertEq(records.length, 1);

        // add more entries to 'namespace'
        store.newDataRecord(0, addressList, addressList, "namespace");
        store.newDataRecord(0, addressList, addressList, "namespace");

        records = store.fetchDataRecords(0, "namespace");
        assertEq(records.length, 3);
    }

    function testConfidentialStoreStoreRetrieve() public {
        // This function tests that we can store and retrieve a value from the record
        Suave.DataRecord memory record = store.newDataRecord(0, addressList, addressList, "namespace");

        bytes memory value = abi.encodePacked("value");
        store.confidentialStore(record.id, "key1", value);

        bytes memory found = store.confidentialRetrieve(record.id, "key1");
        assertEq(keccak256(found), keccak256(value));
    }
}
