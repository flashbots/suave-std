import "suave-std/Context.sol";

contract Example {
    function example() public {
        bytes memory inputs = Context.confidentialInputs();
        address kettle = Context.kettleAddress();
    }
}
