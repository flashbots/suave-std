import "suave-std/Transactions.sol";

contract Example {
    function example() public {
        string memory signingKey = "b71c71a67e1177ad4e901695e1b4b9ee17ae16c6668d313eac2f96dbcda3f291";

        Transactions.EIP1559Request memory txnRequest;
        txnRequest.to = address(0x095E7BAea6a6c7c4c2DfeB977eFac326aF552d87);
        txnRequest.gas = 50000;
        txnRequest.maxPriorityFeePerGas = 10;
        // ...

        Transactions.EIP1559 memory signedTxn = Transactions.signTxn(txnRequest, signingKey);
    }
}
