// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity =0.8.18;

import {PanopticHelper} from "@contracts/periphery/PanopticHelper.sol";
import {SemiFungiblePositionManager} from "@contracts/SemiFungiblePositionManager.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployPool is Script {
    uint256 internal DEPLOYER_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address internal SFPM_ADDRESS = vm.envAddress("SFPM");

    function run() public {
        SemiFungiblePositionManager sfpm = SemiFungiblePositionManager(SFPM_ADDRESS);
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);
        PanopticHelper helper = new PanopticHelper(sfpm);
        console.log("Deployed helper at %s", address(helper));
        vm.stopBroadcast();

    }
}