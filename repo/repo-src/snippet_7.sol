import "solidity-rlp/contracts/RLPReader.sol"

contract SomeContract {
    
    // optional way to attach library functions to these data types.
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    // lets assume that rlpBytes is an encoding of [[1, "nested"], 2, 0x<Address>]
    function someFunctionThatTakesAnEncodedItem(bytes memory rlpBytes) public {
        RLPReader.RLPItem[] memory ls = rlpBytes.toRlpItem().toList(); // must convert to an rlpItem first!

        RLPReader.RLPItem memory item = ls[0]; // the encoding of [1, "nested"].
        item.toList()[0].toUint(); // 1
        string(item.toList()[1].toBytes()); // "nested"

        ls[1].toUint(); // 2
        ls[2].toAddress(); // 0x<Address>
    }

    // lets assume rlpBytes is an encoding of [["sublist"]]
    function someFunctionThatDemonstratesIterators(bytes memory rlpBytes) public {
        RLPReader.Iterator memory iter = rlpBytes.toRlpItem().iterator();
        RLPReader.Iterator memory subIter = iter.next().iterator();

        // iter.hasNext() == false
        // string(subIter.next().toBytes()) == "sublist"
        // subIter.hasNext() == false
    }
}
