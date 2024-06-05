// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./EllipticCurve.sol";
import "forge-std/console2.sol";
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

    function verify(address signer, bytes32 digest, bytes memory sig) internal pure returns (bool) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            v := mload(add(sig, 1))
            r := mload(add(sig, 33))
            s := mload(add(sig, 65))
        }
        return signer == ecrecover(digest, v, r, s);
    }

    function sign(uint256 privateKey, bytes32 digest) internal pure returns (bytes memory) {
        // Step 0: Deterministic choice of k
        // See RFC 6979
        // TODO: replace this with wiser choice
        uint256 k = uint256(
            sha256(
                abi.encodePacked(
                    uint256(0x0101010101010101010101010101010101010101010101010101010101010101), uint8(0), digest
                )
            )
        );

        // Step 1: Ephemeral Key Pair Generation
        (uint256 x1, uint256 y1) = EllipticCurve.ecMul(k, GX, GY, AA, PP); // Ephemeral internal key

        // Step 2: Calculate r and s
        uint256 r = x1 % PP;
        require(r != 0, "Invalid r value");

        uint256 k_inv = EllipticCurve.invMod(k, NN); // Modular inverse of k
        uint256 hashInt = uint256(digest);
        uint256 s = mulmod(k_inv, addmod(hashInt, mulmod(r, privateKey, NN), NN), NN);
        require(s != 0, "Invalid s value");

        // Step 3: Determine recovery id (v)
        uint8 v;
        uint256 y_parity = y1 % 2;

        // Typically, 27 is added to v for legacy reasons, and an additional 2 if the chain ID is included
        // Chain ID is omitted in this example
        if (y_parity == 0) {
            v = 27;
        } else {
            v = 28;
        }
        return abi.encodePacked(v, bytes32(r), bytes32(s));
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
