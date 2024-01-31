// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "../suavelib/Suave.sol";
import "forge-std/Test.sol";

contract ConfidentialStore is Test {
    mapping(bytes32 => Suave.DataRecord[]) private dataRecordsByConditionAndNamespace;
    mapping(Suave.DataId => mapping(string => bytes)) private dataRecordsContent;
    uint64 private numRecords;

    type DataId is bytes16;

    function newDataRecord(
        uint64 decryptionCondition,
        address[] memory allowedPeekers,
        address[] memory allowedStores,
        string memory dataType
    ) public returns (Suave.DataRecord memory) {
        console.log("_ CREATE NEW RECORD *_");
        console.log(numRecords);
        console.logBytes(abi.encodePacked(numRecords));
        console.logBytes32(keccak256(abi.encodePacked(numRecords)));
        console.logBytes16(bytes16(keccak256(abi.encodePacked(numRecords))));
        numRecords++;

        console.log("_ STEP 0_");

        // Use a counter of the records to create a unique key
        Suave.DataId id = Suave.DataId.wrap(bytes16(keccak256(abi.encodePacked(numRecords))));
        numRecords++;
        console.log("_ STEP 1 _");
        Suave.DataRecord memory newRecord;
        newRecord.id = id;
        newRecord.decryptionCondition = decryptionCondition;
        newRecord.allowedPeekers = allowedPeekers;
        newRecord.allowedStores = allowedStores;
        newRecord.version = dataType;
        console.log("_ STEP 2_");
        bytes32 key = keccak256(abi.encodePacked(decryptionCondition, dataType));
        console.log("A1");
        dataRecordsByConditionAndNamespace[key].push(newRecord);
        console.log("A2");

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
}

contract ConfidentialStoreWrapper is Test {
    fallback() external {
        address confidentialStoreAddr = 0x0101010101010101010101010101010101010101;

        // use the origin address to figure out which function
        // is being called
        address addr = address(this);
        bytes4 sig;
        console.log("_ HERE _");

        address[] memory allowedList = new address[](2);
        allowedList[0] = address(this);

        ConfidentialStore store = ConfidentialStore(confidentialStoreAddr);
        store.newDataRecord(0, allowedList, allowedList, "xx");

        console.log(addr);

        if (addr == Suave.CONFIDENTIAL_STORE) {
            // confidentialStore (0xd22a3b0b)
            sig = 0xd22a3b0b;
        } else if (addr == Suave.CONFIDENTIAL_RETRIEVE) {
            // confidentialRetrieve (0xe3b417bc)
            sig = 0xe3b417bc;
        } else if (addr == Suave.FETCH_DATA_RECORDS) {
            // fetchDataRecords (0xccb885c4)
            sig = 0xccb885c4;
        } else if (addr == Suave.NEW_DATA_RECORD) {
            // newDataRecord (0xe3fbcfc3)
            sig = 0xe3fbcfc3;
        } else {
            console.log("_ not found _ ");
            revert("SUCCESS? function");
        }

        bytes memory input = msg.data;

        // call 'confidentialStore' with the selector
        // and the input data.
        (bool success, bytes memory output) = confidentialStoreAddr.call(abi.encodePacked(sig, input));
        console.log("_XXX__");
        console.log("_ SUCCESS? xx yy _");
        console.log(success);
        console.logBytes(output);

        if (!success) {
            revert("Call to confidentialStore failed");
        }

        assembly {
            let location := output
            let length := mload(output)
            return(add(location, 0x20), length)
        }
    }
}

contract Target {
    uint64 public count;

    function incr() public returns (uint64) {
        count++;
        return count;
    }
}

contract TargetProxy {
    Target target;

    constructor(address addr) {
        target = Target(addr);
    }

    fallback() external {
        target.incr();
    }
}
