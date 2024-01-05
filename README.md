# Suave-std

Suave Standard library (`suave-std`) is a collection of helpful contracts and libraries to build Suapps.

## Installation

To install with [Foundry](https://github.com/foundry-rs/foundry):

```bash
forge install flashbots/suave-std
```

## Libraries

### Transactions.sol

Helper library that defines types and encoding/decoding methods for the Ethereum transaction types.

#### Example usage

```solidity
import "suave-std/Transactions.sol";

contract Example {
    function example() {
        Transactions.Legacy memory legacyTxn0 = Transactions.Legacy({
            to: address(0x095E7BAea6a6c7c4c2DfeB977eFac326aF552d87),
            gas: 50000,
            gasPrice: 10,
            value: 10,
            ...
        });

        // Encode to RLP
        bytes memory rlp = Transactions.encodeLegacyRLP(legacyTxn0);

        // Decode from RLP
        Transactions.Legacy memory legacyTxn1 = Transactions.decodeLegacyRLP(rlp);
    }
}
```
