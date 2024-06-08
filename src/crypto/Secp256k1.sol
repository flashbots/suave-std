// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "elliptic-curve-solidity/contracts/EllipticCurve.sol";
import "../utils/HexStrings.sol";

/// @notice Secp256k1 is a library with utilities to work with the secp256k1 curve.
library Secp256k1 {
    uint256 internal constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 internal constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 internal constant AA = 0;
    uint256 internal constant BB = 7;
    uint256 internal constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 internal constant NN = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function derivePubKey(uint256 privKey) internal pure returns (uint256 qx, uint256 qy) {
        (qx, qy) = EllipticCurve.ecMul(privKey, GX, GY, AA, PP);
    }

    function deriveAddress(uint256 privKey) internal pure returns (address) {
        (uint256 qx, uint256 qy) = derivePubKey(privKey);
        bytes memory ser = bytes.concat(bytes32(qx), bytes32(qy));
        return address(uint160(uint256(keccak256(ser))));
    }

    // @notice deriveAddress returns the address corresponding to the private key
    // @param privKey is the private key
    // @return address is the address derived from the private key
    function deriveAddress(string memory privKey) internal pure returns (address) {
        bytes memory privKeyBytes = HexStrings.fromHexString(privKey);
        require(privKeyBytes.length == 32, "Invalid private key length");

        return deriveAddress(uint256(bytes32(privKeyBytes)));
    }
}
