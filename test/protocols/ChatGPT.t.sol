// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Test.sol";
import "src/protocols/ChatGPT.sol";

contract ChatGPTTest is Test, SuaveEnabled {
    function testChatGPT() public {
        (ChatGPT chatgpt, string memory apiKey) = getChatGPT();

        ChatGPT.Message[] memory messages = new ChatGPT.Message[](1);
        messages[0] = ChatGPT.Message(ChatGPT.Role.User, "Say this is a test!");

        string memory expected = "This is a test!";
        string memory found = chatgpt.complete(apiKey, messages);

        assertEq(found, expected, "ChatGPT did not return the expected result");
    }

    function getChatGPT() public returns (ChatGPT chatgpt, string memory apiKey) {
        // NOTE: tried to do it with envOr but it did not worked
        try vm.envString("CHATGPT_API_KEY") returns (string memory apiKeyEnv) {
            if (bytes(apiKeyEnv).length == 0) {
                vm.skip(true);
            }
            chatgpt = new ChatGPT();
            apiKey = apiKeyEnv;
        } catch {
            vm.skip(true);
        }
    }
}
