// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "forge-std/console.sol";

interface Vm {
    function ffi(string[] calldata commandInput) external view returns (bytes memory result);
}

contract Wrapper {
    Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function forgeIt(bytes memory addr, bytes memory data) internal view returns (bytes memory) {
        string memory addrHex = iToHex(addr);
        string memory dataHex = iToHex(data);

        string[] memory inputs = new string[](4);
        inputs[0] = "suave";
        inputs[1] = "forge";
        inputs[2] = addrHex;
        inputs[3] = dataHex;

        bytes memory res = vm.ffi(inputs);
        return res;
    }

    function iToHex(bytes memory buffer) public pure returns (string memory) {
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

    fallback() external {
        // bytes memory data = forgeIt(abi.encodePacked(address(this)), msg.data);
        bytes memory byteArray = abi.encode("aaaaa");

        assembly {
            // Get the free memory pointer
            let memPtr := mload(0x40)

            // Set the length of the byte array
            mstore(byteArray, 0x20) // Set the length to 32 bytes (1 slot)
            mstore(add(byteArray, 0x20), 0x41414141) // Set the first 4 bytes of data (example 'AAAA')

            // Update the free memory pointer
            mstore(0x40, add(memPtr, 0x60))

            // Return the byte array
            return(memPtr, 0x20)
        }
    }
}
