import "suave-std/protocols/EthJsonRPC.sol";

contract Example {
    function example() public {
        EthJsonRPC jsonrpc = new EthJsonRPC("http://...");
        jsonrpc.nonce(address(this));
    }
}
