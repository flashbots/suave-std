// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

contract TestOther is Test {
    struct Log {
        address addr;
        bytes32[] topics;
        bytes data;
    }

    struct Result {
        Log[] logs;
    }

    // generated with suave-geth TestE2E_EmitLogs test
    bytes constant encodedResultTestcase =
        hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000420000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001dc013ea64717e828d19b2a2ee201871627a4a65b8e96984868b9391a327be18a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000023ab4eb7c630180e1144d0a956c71b3cb538ea0b9566b6136fe7a87cb222249d20000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000039e4d9541d8ffa37d1346e0a2ee0dd6cb444641c8458993777d3d06e9da3bd66600000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000004b1b8bb6d3c04a82bd66f1d7dbecf2754edafb96d47af76845f87c5245afaec2d00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003";

    function findStartIndex(bytes memory data) private pure returns (uint256) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == bytes1(0xff)) {
                return i;
            }
        }
        return data.length; // Not found
    }

    function decodeLogs(bytes memory inputData) public {
        uint256 magicSequenceIndex = findStartIndex(inputData);
        require(magicSequenceIndex != inputData.length, "Magic sequence not found");

        // because we have to skip the magic number
        magicSequenceIndex += 1;

        // Calculate the length of the data to decode
        uint256 dataLength = inputData.length - magicSequenceIndex;

        // Initialize memory for the data to decode
        bytes memory dataToDecode = new bytes(dataLength);

        // Copy the data to decode into the memory array
        for (uint256 i = 0; i < dataLength; i++) {
            dataToDecode[i] = inputData[magicSequenceIndex + i];
        }

        console.logBytes(dataToDecode);

        Result memory result = abi.decode(dataToDecode, (Result));
    }

    function emitLog(Log memory log) public {
        bytes memory logData = log.data;
        uint256 dataLength = logData.length;

        if (log.topics.length == 0) {
            assembly {
                log0(add(logData, 32), dataLength)
            }
        } else if (log.topics.length == 1) {
            bytes32 topic0 = log.topics[0];

            assembly {
                log1(add(logData, 32), dataLength, topic0)
            }
        } else if (log.topics.length == 2) {
            bytes32 topic0 = log.topics[0];
            bytes32 topic1 = log.topics[1];

            assembly {
                log2(add(logData, 32), dataLength, topic0, topic1)
            }
        } else if (log.topics.length == 3) {
            bytes32 topic0 = log.topics[0];
            bytes32 topic1 = log.topics[1];
            bytes32 topic2 = log.topics[2];

            assembly {
                log3(add(logData, 32), dataLength, topic0, topic1, topic2)
            }
        } else if (log.topics.length == 4) {
            bytes32 topic0 = log.topics[0];
            bytes32 topic1 = log.topics[1];
            bytes32 topic2 = log.topics[2];
            bytes32 topic3 = log.topics[3];

            assembly {
                log4(add(logData, 32), dataLength, topic0, topic1, topic2, topic3)
            }
        }
    }

    // getEmittedLog returns the emitted logs in Forge as a Log struct.
    function getEmittedLogs() private returns (Log[] memory) {
        VmSafe.Log[] memory logs = vm.getRecordedLogs();

        Log[] memory logs11 = new Log[](logs.length);
        for (uint256 i = 0; i < logs.length; i++) {
            Log memory log;
            log.addr = logs[i].emitter;
            log.topics = logs[i].topics;
            log.data = logs[i].data;

            logs11[i] = log;
        }

        return logs11;
    }

    // equalLogs checks if two Log structs are equal.
    function equalLogs(Log memory a, Log memory b) internal {
        assertEq(a.addr, b.addr);
        assertEq(a.topics.length, b.topics.length);
        for (uint256 i = 0; i < a.topics.length; i++) {
            assertEq(a.topics[i], b.topics[i]);
        }
        assertEq(a.data, b.data);
    }

    event EventAnonymous() anonymous;
    event EventTopic1();
    event EventTopic2(uint256 indexed num1, uint256 numNoIndex);
    event EventTopic3(uint256 indexed num1, uint256 indexed num2, uint256 numNoIndex);
    event EventTopic4(uint256 indexed num1, uint256 indexed num2, uint256 indexed num3, uint256 numNoIndex);
    event EventWithMultipleArgs(uint256 indexed num1, uint256 num2, uint256 num3);

    // testEmitLog tests that the logs emitted with 'emitLog' have the same
    // values as the logs emitted with 'emit '.
    function testEmitLog() public {
        vm.recordLogs();

        emit EventAnonymous();
        emit EventTopic1();
        emit EventTopic2(1, 1);
        emit EventTopic3(1, 2, 2);
        emit EventTopic4(1, 2, 3, 4);
        emit EventWithMultipleArgs(1, 2, 3);

        // get all the emitted logs and send them again with
        // the low-level emitLog function
        Log[] memory logs = getEmittedLogs();

        for (uint256 i = 0; i < logs.length; i++) {
            emitLog(logs[i]);
        }

        // get the emitted logs from 'emitLog' and compare them with the
        // original emitted logs
        Log[] memory logs1 = getEmittedLogs();

        for (uint256 i = 0; i < logs.length; i++) {
            equalLogs(logs[i], logs1[i]);
        }
    }

    function testExecResult_LogsTestcases() public {
        // validate that we can parse the result testcase generated by suave-geth
        (Log[] memory logs) = abi.decode(encodedResultTestcase, (Log[]));

        assertEq(logs.length, 5);
        assertEq(logs[0].topics.length, 0);
        assertEq(logs[1].topics.length, 1);
        assertEq(logs[2].topics.length, 2);
        assertEq(logs[3].topics.length, 3);
        assertEq(logs[4].topics.length, 4);

        // 0 and 1 do not have data and 2.. have data
        assertEq(logs[0].data.length, 0);
        assertEq(logs[1].data.length, 0);
        for (uint256 i = 2; i < logs.length; i++) {
            assertNotEq(logs[i].data.length, 0);
        }

        // all of them have the same address (0x030)
        for (uint256 i = 0; i < logs.length; i++) {
            assertEq(logs[i].addr, 0x0300000000000000000000000000000000000000);
        }
    }
}
