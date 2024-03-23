import "suave-std/Context.sol";

contract Example {
    function example() {
        bytes memory inputs = Context.confidentialInputs();
        address kettle = Context.kettleAddress();
    }
}
