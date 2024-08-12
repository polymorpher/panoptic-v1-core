// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity =0.8.18;

import {PanopticFactory} from "@contracts/PanopticFactory.sol";
import {PanopticPool} from "@contracts/PanopticPool.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployPool is Script {
    function run() public {
        uint256 DEPLOYER_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address FACTORY_ADDRESS = vm.envAddress("PANOPTIC_FACTORY_ADDRESS");
        address TOKEN0_ADDRESS = vm.envAddress("TOKEN0_ADDRESS");
        address TOKEN1_ADDRESS = vm.envAddress("TOKEN1_ADDRESS");
        uint24 FEE = uint24(vm.envUint("FEE"));
        uint96 SALT = uint96(vm.envUint("SALT"));
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);
        PanopticFactory factory = PanopticFactory(FACTORY_ADDRESS);
        console.log("Deploying new Panoptic pool... Token0=%s, token1=%s, fee=%s, salt=%s", TOKEN0_ADDRESS, TOKEN1_ADDRESS);
        console.log("  - fee=%s, salt=%s", FEE, SALT);
        PanopticPool pool = factory.deployNewPool(TOKEN0_ADDRESS, TOKEN1_ADDRESS, FEE, SALT);
        console.log("Deployed pool to %s", pool);

    }
}