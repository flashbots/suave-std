import "suave-std/protocols/ChatGPT.sol";

contract Example {
    function example() public {
        ChatGPT chatgpt = new ChatGPT("apikey");

        ChatGPT.Message[] memory messages = new ChatGPT.Message[](1);
        messages[0] = ChatGPT.Message(ChatGPT.Role.User, "How do I write a Suapp with suave-std?");

        chatgpt.complete(messages);
    }
}
