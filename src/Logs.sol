// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./suavelib/Suave.sol";

library Logs {
    struct Log {
        address addr;
        bytes32[] topics;
        bytes data;
    }

    bytes constant MAGIC_SEQUENCE = hex"543543";

    function findStartIndex(bytes memory data) internal pure returns (uint256) {
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == MAGIC_SEQUENCE[0]) {
                // Check if current byte matches the first byte of MAGIC_SEQUENCE
                bool isMatch = true;
                for (uint256 j = 1; j < MAGIC_SEQUENCE.length; j++) {
                    // Check subsequent bytes
                    if (i + j >= data.length || data[i + j] != MAGIC_SEQUENCE[j]) {
                        isMatch = false;
                        break;
                    }
                }
                if (isMatch) {
                    return i + MAGIC_SEQUENCE.length; // Return the index after the magic sequence
                }
            }
        }
        return data.length; // Not found
    }

    function decodeLogs(bytes memory inputData) internal {
        uint256 magicSequenceIndex = findStartIndex(inputData);
        if (magicSequenceIndex == inputData.length) {
            return; // Magic sequence not found, skip logs
        }

        // Calculate the length of the data to decode
        uint256 dataLength = inputData.length - magicSequenceIndex;

        // Initialize memory for the data to decode
        bytes memory dataToDecode = new bytes(dataLength);

        // Copy the data to decode into the memory array
        for (uint256 i = 0; i < dataLength; i++) {
            dataToDecode[i] = inputData[magicSequenceIndex + i];
        }

        (Log[] memory logs) = abi.decode(dataToDecode, (Log[]));
        for (uint256 i = 0; i < logs.length; i++) {
            emitLog(logs[i]);
        }
    }

    function emitLog(Log memory log) internal {
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
}
