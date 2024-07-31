// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Test.sol";
import "src/suavelib/Suave.sol";
import "src/Context.sol";
import {Suapp} from "src/Suapp.sol";

contract TestForge is Test, SuaveEnabled {
    address[] public addressList = [0xC8df3686b4Afb2BB53e60EAe97EF043FE03Fb829];

    function testForgeConfidentialStoreFetch() public {
        Suave.newDataRecord(0, addressList, addressList, "namespace");

        Suave.DataRecord[] memory records = Suave.fetchDataRecords(0, "namespace");
        assertEq(records.length, 1);

        Suave.newDataRecord(0, addressList, addressList, "namespace");
        Suave.newDataRecord(0, addressList, addressList, "namespace");

        Suave.DataRecord[] memory records2 = Suave.fetchDataRecords(0, "namespace");
        assertEq(records2.length, 3);

        resetConfidentialStore();

        Suave.DataRecord[] memory records3 = Suave.fetchDataRecords(0, "namespace");
        assertEq(records3.length, 0);
    }

    function testForgeConfidentialStoreRecordStore() public {
        // test with the wildcard
        _testForgeConfidentialStoreRecordStore(addressList);

        // test with address(this) as the allowed address
        address[] memory addrList = new address[](1);
        addrList[0] = address(this);

        _testForgeConfidentialStoreRecordStore(addrList);
    }

    function _testForgeConfidentialStoreRecordStore(address[] memory addrList) public {
        Suave.DataRecord memory record = Suave.newDataRecord(0, addrList, addrList, "namespace");

        bytes memory value = abi.encode("suave works with forge!");
        Suave.confidentialStore(record.id, "key1", value);

        bytes memory found = Suave.confidentialRetrieve(record.id, "key1");
        assertEq(keccak256(found), keccak256(value));
    }

    function testForgeContextConfidentialInputs() public {
        bytes memory found1 = Context.confidentialInputs();
        assertEq(found1.length, 0);

        bytes memory input = hex"abcd";
        ctx.setConfidentialInputs(input);

        bytes memory found2 = Context.confidentialInputs();
        assertEq0(input, found2);

        ctx.resetConfidentialInputs();

        bytes memory found3 = Context.confidentialInputs();
        assertEq(found3.length, 0);
    }

    function testForgeContextKettleAddress() public {
        address found1 = Context.kettleAddress();
        assertEq(found1, address(0));

        ctx.setKettleAddress(address(this));

        address found2 = Context.kettleAddress();
        assertEq(found2, address(this));

        ctx.resetKettleAddress();

        address found3 = Context.kettleAddress();
        assertEq(found3, address(0));
    }
}

contract TestConfidential is Test, SuaveEnabled {
    /**
     * @notice Assumes 36 bytes are given, returns `data[4..]`.
     */
    function stripSelector(bytes memory data) internal pure returns (bytes memory trimmedData) {
        trimmedData = new bytes(data.length - 4);
        assembly {
            mstore(add(trimmedData, 0x20), sub(mload(add(data, 0x20)), 0x04))
            mstore(add(trimmedData, 0x20), mload(add(data, 0x24)))
        }
    }

    function testConfidentialResponse() public {
        NumberSuapp suapp = new NumberSuapp();

        ctx.setConfidentialInputs(abi.encode(123));

        // call confidential/offchain function, verify calldata
        bytes memory suaveCalldata = suapp.setNumber();
        assertEq(suaveCalldata.length, 4 + 32);
        uint256 num = abi.decode(stripSelector(suaveCalldata), (uint256));
        assertEq(num, 123);

        // call onchain function, verify number
        suapp.onSetNumber(num);
        assertEq(suapp.number(), num);
    }
}

contract NumberSuapp is Suapp {
    uint256 public number;

    function onSetNumber(uint256 num) public {
        number = num;
    }

    function setNumber() public confidential returns (bytes memory) {
        uint256 num = abi.decode(Context.confidentialInputs(), (uint256));
        return abi.encodeWithSelector(this.onSetNumber.selector, num);
    }
}
