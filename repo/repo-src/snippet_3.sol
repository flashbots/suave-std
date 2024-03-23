import "suave-std/protocols/EthJsonRPC.sol";

contract Example {
    function example() {
        EthJsonRPC jsonrpc = new EthJsonRPC("http://...");
        jsonrpc.nonce(address(this));
    }
}
