import "suave-std/protocols/MevShare.sol";

contract Example {
    function example() {
        Transactions.Legacy memory legacyTxn0 = Transactions.Legacy({});
        bytes memory rlp = Transactions.encodeRLP(legacyTxn0);

        MevShare.Bundle memory bundle;
        bundle.bodies = new bytes[](1);
        bundle.bodies[0] = rlp;
        // ...

        MevShare.sendBundle(bundle);
    }
}
