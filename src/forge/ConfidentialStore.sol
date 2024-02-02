// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "../suavelib/Suave.sol";
import "forge-std/Test.sol";

contract ConfidentialStore is Test {
    mapping(bytes32 => Suave.DataRecord[]) private dataRecordsByConditionAndNamespace;
    mapping(Suave.DataId => mapping(string => bytes)) private dataRecordsContent;
    uint64 private numRecords;

    type DataId is bytes16;

    constructor() {
        vm.record();
    }

    function newDataRecord(
        uint64 decryptionCondition,
        address[] memory allowedPeekers,
        address[] memory allowedStores,
        string memory dataType
    ) public returns (Suave.DataRecord memory) {
        numRecords++;

        // Use a counter of the records to create a unique key
        Suave.DataId id = Suave.DataId.wrap(bytes16(keccak256(abi.encodePacked(numRecords))));
        numRecords++;

        Suave.DataRecord memory newRecord;
        newRecord.id = id;
        newRecord.decryptionCondition = decryptionCondition;
        newRecord.allowedPeekers = allowedPeekers;
        newRecord.allowedStores = allowedStores;
        newRecord.version = dataType;

        // Use a composite index to store the records for the 'fetchDataRecords' function
        bytes32 key = keccak256(abi.encodePacked(decryptionCondition, dataType));
        dataRecordsByConditionAndNamespace[key].push(newRecord);

        return newRecord;
    }

    function fetchDataRecords(uint64 cond, string memory namespace) public view returns (Suave.DataRecord[] memory) {
        bytes32 key = keccak256(abi.encodePacked(cond, namespace));
        return dataRecordsByConditionAndNamespace[key];
    }

    function confidentialStore(Suave.DataId dataId, string memory key, bytes memory value) public {
        dataRecordsContent[dataId][key] = value;
    }

    function confidentialRetrieve(Suave.DataId dataId, string memory key) public view returns (bytes memory) {
        return dataRecordsContent[dataId][key];
    }

    function reset() public {
        (, bytes32[] memory writes) = vm.accesses(address(this));
        for (uint256 i = 0; i < writes.length; i++) {
            vm.store(address(this), writes[i], 0);
        }
    }
}

contract ConfidentialStoreWrapper is Test {
    fallback() external {
        address confidentialStoreAddr = 0x0101010101010101010101010101010101010101;

        address addr = address(this);
        bytes4 sig;

        // You can use 'forge selectors list' to retrieve the function signatures
        if (addr == Suave.CONFIDENTIAL_STORE) {
            sig = 0xd22a3b0b;
        } else if (addr == Suave.CONFIDENTIAL_RETRIEVE) {
            sig = 0xe3b417bc;
        } else if (addr == Suave.FETCH_DATA_RECORDS) {
            sig = 0xccb885c4;
        } else if (addr == Suave.NEW_DATA_RECORD) {
            sig = 0xe3fbcfc3;
        } else {
            revert("function signature not found in the confidential store");
        }

        bytes memory input = msg.data;

        // call 'confidentialStore' with the selector and the input data.
        (bool success, bytes memory output) = confidentialStoreAddr.call(abi.encodePacked(sig, input));
        if (!success) {
            revert("Call to confidentialStore failed");
        }

        if (addr == Suave.CONFIDENTIAL_RETRIEVE) {
            // special case we have to unloop the value from the abi
            // since it comes encoded as tuple() but we return the value normally
            // this was a special case that was not fixed yet in suave-geth.
            output = abi.decode(output, (bytes));
        }

        assembly {
            let location := output
            let length := mload(output)
            return(add(location, 0x20), length)
        }
    }
}
