import "suave-std/Transactions.sol";

contract Example {
    function example() {
        Transactions.EIP155Request memory txn0 = Transactions.EIP155Request({
            to: address(0x095E7BAea6a6c7c4c2DfeB977eFac326aF552d87),
            gas: 50000,
            gasPrice: 10,
            value: 10,
            ...
        });

        // Encode to RLP
        bytes memory rlp = Transactions.encodeRLP(txn0);

        // Decode from RLP
        Transactions.Legacy memory txn = Transactions.decodeRLP(rlp);
    }
}
