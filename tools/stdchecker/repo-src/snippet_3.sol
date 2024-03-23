import "suave-std/protocols/MevShare.sol";
import "suave-std/Transactions.sol";

contract Example {
    function example() public {
        Transactions.EIP155 memory legacyTxn0;
        // fill the transaction fields
        // legacyTxn0.to = ...
        // legacyTxn0.gas = ...

        bytes memory rlp = Transactions.encodeRLP(legacyTxn0);

        MevShare.Bundle memory bundle;
        bundle.bodies = new bytes[](1);
        bundle.bodies[0] = rlp;
        // ...

        MevShare.sendBundle("http://<relayer-url>", bundle);
    }
}
