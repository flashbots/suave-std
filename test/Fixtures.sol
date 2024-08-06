// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface fixturesVmSafeRef {
    function readFile(string calldata path) external view returns (string memory data);
}

library Fixtures {
    fixturesVmSafeRef constant vm = fixturesVmSafeRef(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function readFixture(string memory path) internal view returns (string memory) {
        string memory fullPath = string.concat("./test/fixtures/", path);
        return vm.readFile(fullPath);
    }

    function validate(string memory path, string memory value) internal view {
        string memory data = readFixture(path);
        if (keccak256(abi.encodePacked(data)) != keccak256(abi.encodePacked(value))) {
            string memory revertMsg = string.concat("Fixtures.validate: expected: ", data, " != ", value);
            revert(revertMsg);
        }
    }
}
