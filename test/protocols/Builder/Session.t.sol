// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/protocols/Builder/Session.sol";
import {Types} from "src/protocols/Builder/Types.sol";
import "src/suavelib/Suave.sol";
import "../../Fixtures.sol";
import "src/Test.sol";
import "src/Transactions.sol";

contract Example {
    event SomeEvent(uint256 value);

    function get(uint256 value) public {
        emit SomeEvent(value);
    }
}

contract SuaveBuilderSessionTest is Test, SuaveEnabled {
    function testNewSession() public {
        /*
        Types.BuildBlockArgs memory args;
        args.slot = 1;
        args.proposerPubkey = hex"1234";
        args.parent = hex"";
        args.timestamp = 123;
        args.feeRecipient = address(0x1234);
        args.gasLimit = 123;
        args.random = hex"1234";
        args.extra = hex"1234";
        args.beaconRoot = hex"1234";
        args.fillPending = true;

        Session session = new Session("http://localhost:8545");
        session.start(args);

        string memory signingKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

        Transactions.EIP155Request memory txnrequest = Transactions.EIP155Request({
            to: address(0x00000000000000000000000000000000DeaDBeef),
            gas: 1000000,
            gasPrice: 875000000,
            value: 1,
            nonce: 0,
            data: bytes(""),
            chainId: 1337
        });

        Transactions.EIP155 memory response = Transactions.signTxn(txnrequest, signingKey);
        session.addTransaction(response);
        */

        Types.BuildBlockArgs memory args;
        args.slot = 1;
        args.proposerPubkey = hex"1234";
        args.parent = hex"";
        args.timestamp = 123;
        args.feeRecipient = address(0x1234);
        args.gasLimit = 123;
        args.random = hex"1234";
        args.extra = hex"1234";
        args.beaconRoot = hex"1234";
        args.fillPending = true;

        Session session = new Session("http://localhost:8545");
        session.start(args);

        string memory signingKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

        // call the "Example" contract
        bytes memory targetCall = abi.encodeWithSignature("get(uint256)", 1234);

        console.log("-- target call --");
        console.logBytes(targetCall);

        Transactions.EIP155Request memory txnrequest = Transactions.EIP155Request({
            to: address(0x5FbDB2315678afecb367f032d93F642f64180aa3),
            gas: 1000000,
            gasPrice: 875000000,
            value: 0,
            nonce: 1,
            data: targetCall,
            chainId: 1337
        });

        Transactions.EIP155 memory response = Transactions.signTxn(txnrequest, signingKey);
        Types.SimulateTransactionResult memory result = session.addTransaction(response);

        console.log(result.logs[0].addr);

        // deployContractOnSuavex(type(Example).creationCode);
    }
}
