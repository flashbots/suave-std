// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/Gateway.sol";
import "src/Test.sol";

contract TestGateway is Test, SuaveEnabled {
    function testGateway() public {
        string memory endpoint = getEthJsonRPC();
        Gateway gateway = new Gateway(endpoint, address(0x00000000219ab540356cBB839Cbe05303d7705Fa));
        DepositContract depositContract = DepositContract(address(gateway));

        bytes memory count = depositContract.get_deposit_count();
        require(count.length > 0, "count is empty");
    }

    function getEthJsonRPC() public returns (string memory) {
        try vm.envString("JSONRPC_ENDPOINT") returns (string memory endpoint) {
            return endpoint;
        } catch {
            vm.skip(true);
        }
        revert("this code path should never be reached in normal circumstances");
    }
}

interface DepositContract {
    function get_deposit_count() external view returns (bytes memory);
}
