// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Test.sol";
import "src/suavelib/Suave.sol";
import "src/Context.sol";
import "src/crypto/Secp256k1.sol";

contract TestSecp256K1 is Test, SuaveEnabled {
    function testRecoverAddress() public pure {
        string memory signingKey = "b71c71a67e1177ad4e901695e1b4b9ee17ae16c6668d313eac2f96dbcda3f291";

        address expected = 0x71562b71999873DB5b286dF957af199Ec94617F7;
        address found = Secp256k1.deriveAddress(signingKey);
        assert(expected == found);
    }
}
