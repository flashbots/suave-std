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
    string constant signingKey = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
    string constant execNodeEndpoint = "http://localhost:8545";
    // pair of bls private and public keys
    string constant blsPrivKey = "68a84428e388a5de81fa54f6f91a34d28f09692262c0ee4da81935a4e832ae19";
    string constant blsPubKey =
        "b6b973370f9684a2bc0b89f873b772b01269277196e84b69fe8ebad8908e777c09cdfad9d4a2f849e12ecd12ba9dce20";

    function getBlockBuildArgs() public pure returns (Types.BuildBlockArgs memory) {
        Types.BuildBlockArgs memory args;
        args.slot = 1;
        args.proposerPubkey = hex"1234";
        args.parent = hex""; // root is empty, take the latest header
        args.timestamp = 123;
        args.feeRecipient = address(0x1234);
        args.gasLimit = 123;
        args.random = hex"1234";
        args.extra = hex"1234";
        args.beaconRoot = hex"1234";
        args.fillPending = true;

        return args;
    }

    function getValidTxn() public returns (Transactions.EIP155 memory) {
        bytes memory targetCall = abi.encodeWithSignature("get(uint256)", 1234);

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
        return response;
    }

    function testBuilderAPI_AddTransaction() public {
        Types.BuildBlockArgs memory args = getBlockBuildArgs();

        Session session = new Session(getBuilderSessionURL());
        session.start(args);

        // call the "Example" contract
        Transactions.EIP155 memory response = getValidTxn();
        Types.SimulateTransactionResult memory result = session.addTransaction(response);

        assertEq(result.success, true);
        assertEq(result.logs.length, 1);
        assertEq(result.logs[0].addr, 0x5FbDB2315678afecb367f032d93F642f64180aa3);
        assertEq(result.logs[0].topics[0], keccak256("SomeEvent(uint256)"));
        assertEq(result.logs[0].data, hex"00000000000000000000000000000000000000000000000000000000000004d2");

        // Try to send the same transaction again in the session should fail because
        // the nonce is already used
        result = session.addTransaction(response);

        assertEq(result.success, false);
        assertNotEq(bytes(result.error).length, 0);
    }

    function testBuilderAPI_BuildBlock() public {
        Types.BuildBlockArgs memory args = getBlockBuildArgs();

        Session session = new Session(getBuilderSessionURL());
        session.start(args);

        // send a valid transaction
        Transactions.EIP155 memory response = getValidTxn();
        Types.SimulateTransactionResult memory result = session.addTransaction(response);
        assertEq(result.success, true);

        // build the block
        session.buildBlock();
    }

    function testBuilderAPI_BidBuiltBlock() public {
        Types.BuildBlockArgs memory args = getBlockBuildArgs();

        Session session = new Session(getBuilderSessionURL());
        session.start(args);

        // send a valid transaction
        Transactions.EIP155 memory response = getValidTxn();
        Types.SimulateTransactionResult memory result = session.addTransaction(response);
        assertEq(result.success, true);

        // build the block
        session.buildBlock();
        session.bid(blsPubKey);
    }

    function getBuilderSessionURL() public returns (string memory) {
        try vm.envString("BUILDER_SESSION_URL") returns (string memory sessionURL) {
            if (bytes(sessionURL).length == 0) {
                vm.skip(true);
            }
            return sessionURL;
        } catch {
            vm.skip(true);
        }
        revert("this code path should never be reached in normal circumstances");
    }
}
