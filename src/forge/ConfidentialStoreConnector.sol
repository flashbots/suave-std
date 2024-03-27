// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./ConfidentialStore.sol";
import "../suavelib/Suave.sol";

contract ConfidentialStoreConnector {
    fallback() external {
        address confidentialStoreAddr = 0x0101010101010101010101010101010101010101;

        address addr = address(this);
        bytes memory input;

        if (addr == Suave.CONFIDENTIAL_STORE) {
            (Suave.DataId dataId, string memory key, bytes memory val) =
                abi.decode(msg.data, (Suave.DataId, string, bytes));

            input =
                abi.encodeWithSignature("confidentialStore(bytes16,string,bytes,address)", dataId, key, val, msg.sender);
        } else if (addr == Suave.CONFIDENTIAL_RETRIEVE) {
            (Suave.DataId dataId, string memory key) = abi.decode(msg.data, (Suave.DataId, string));

            input = abi.encodeWithSignature("confidentialRetrieve(bytes16,string,address)", dataId, key, msg.sender);
        } else if (addr == Suave.FETCH_DATA_RECORDS) {
            input = abi.encodePacked(ConfidentialStore.fetchDataRecords.selector, msg.data);
        } else if (addr == Suave.NEW_DATA_RECORD) {
            input = abi.encodePacked(ConfidentialStore.newDataRecord.selector, msg.data);
        } else {
            revert("function signature not found in the confidential store");
        }

        (bool success, bytes memory output) = confidentialStoreAddr.call(input);
        if (!success) {
            revert("Call to confidentialStore failed");
        }

        if (addr == Suave.CONFIDENTIAL_RETRIEVE) {
            // special case we have to unroll the value from the abi
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
