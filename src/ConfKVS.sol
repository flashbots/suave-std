// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Suave} from "src/suavelib/Suave.sol";

struct ConfStore {
    address[] allowedPeekers;
    address[] allowedStores;
    string namespace;
}

struct ConfRecord {
    Suave.DataId id;
    string key;
}

library ConfKVS {
    /// Create a new data record and store the value. Data is available to consumers immediately.
    function set(ConfStore memory cs, string memory key, bytes memory value)
        internal
        returns (ConfRecord memory confRecord)
    {
        Suave.DataRecord memory rec = Suave.newDataRecord(
            0, cs.allowedPeekers, cs.allowedStores, string(abi.encodePacked(cs.namespace, "::", key))
        );
        Suave.confidentialStore(rec.id, key, value);
        confRecord = ConfRecord(rec.id, key);
    }

    /// Retrieve the value from the data record.
    function get(ConfRecord memory confRecord) internal returns (bytes memory) {
        return Suave.confidentialRetrieve(confRecord.id, confRecord.key);
    }
}
