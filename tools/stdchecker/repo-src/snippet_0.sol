import "suave-std/Transactions.sol";

contract Example {
    function example() public {
        Transactions.EIP155 memory txn0;
        // fill the transaction fields
        // legacyTxn0.to = ...
        // legacyTxn0.gas = ...

        // Encode to RLP
        bytes memory rlp = Transactions.encodeRLP(txn0);

        // Decode from RLP
        Transactions.EIP155 memory txn = Transactions.decodeRLP_EIP155(rlp);
    }
}
