import "forge-std/Test.sol";

contract TestContract is Test {
    using stdStorage for StdStorage;

    Storage test;

    function setUp() public {
        test = new Storage();
    }

    function testFindExists() public {
        // Lets say we want to find the slot for the public
        // variable `exists`. We just pass in the function selector
        // to the `find` command
        uint256 slot = stdstore.target(address(test)).sig("exists()").find();
        assertEq(slot, 0);
    }

    function testWriteExists() public {
        // Lets say we want to write to the slot for the public
        // variable `exists`. We just pass in the function selector
        // to the `checked_write` command
        stdstore.target(address(test)).sig("exists()").checked_write(100);
        assertEq(test.exists(), 100);
    }

    // It supports arbitrary storage layouts, like assembly based storage locations
    function testFindHidden() public {
        // `hidden` is a random hash of a bytes, iteration through slots would
        // not find it. Our mechanism does
        // Also, you can use the selector instead of a string
        uint256 slot = stdstore.target(address(test)).sig(test.hidden.selector).find();
        assertEq(slot, uint256(keccak256("my.random.var")));
    }

    // If targeting a mapping, you have to pass in the keys necessary to perform the find
    // i.e.:
    function testFindMapping() public {
        uint256 slot = stdstore
            .target(address(test))
            .sig(test.map_addr.selector)
            .with_key(address(this))
            .find();
        // in the `Storage` constructor, we wrote that this address' value was 1 in the map
        // so when we load the slot, we expect it to be 1
        assertEq(uint(vm.load(address(test), bytes32(slot))), 1);
    }

    // If the target is a struct, you can specify the field depth:
    function testFindStruct() public {
        // NOTE: see the depth parameter - 0 means 0th field, 1 means 1st field, etc.
        uint256 slot_for_a_field = stdstore
            .target(address(test))
            .sig(test.basicStruct.selector)
            .depth(0)
            .find();

        uint256 slot_for_b_field = stdstore
            .target(address(test))
            .sig(test.basicStruct.selector)
            .depth(1)
            .find();

        assertEq(uint(vm.load(address(test), bytes32(slot_for_a_field))), 1);
        assertEq(uint(vm.load(address(test), bytes32(slot_for_b_field))), 2);
    }
}

// A complex storage contract
contract Storage {
    struct UnpackedStruct {
        uint256 a;
        uint256 b;
    }

    constructor() {
        map_addr[msg.sender] = 1;
    }

    uint256 public exists = 1;
    mapping(address => uint256) public map_addr;
    // mapping(address => Packed) public map_packed;
    mapping(address => UnpackedStruct) public map_struct;
    mapping(address => mapping(address => uint256)) public deep_map;
    mapping(address => mapping(address => UnpackedStruct)) public deep_map_struct;
    UnpackedStruct public basicStruct = UnpackedStruct({
        a: 1,
        b: 2
    });

    function hidden() public view returns (bytes32 t) {
        // an extremely hidden storage slot
        bytes32 slot = keccak256("my.random.var");
        assembly {
            t := sload(slot)
        }
    }
}
