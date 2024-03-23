import "forge-std/Test.sol";
import "src/Test.sol";
import "src/suavelib/Suave.sol";

contract TestForge is Test, SuaveEnabled {
    function testConfidentialInputs() public {
        bytes memory input = hex"abcd";
        ctx.setConfidentialInputs(input);

        bytes memory found2 = Suave.confidentialInputs();
        assertEq0(input, found2);
    }
}
