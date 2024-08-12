// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity =0.8.18;

import {PanopticFactory} from "@contracts/PanopticFactory.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployPool is Script {
    function run() public {
        uint256 DEPLOYER_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 FACTORY_ADDRESS = vm.envAddress("PANOPTIC_FACTORY_ADDRESS");
        uint256 TOKEN0_ADDRESS = vm.envAddress("TOKEN0_ADDRESS");
        uint256 TOKEN1_ADDRESS = vm.envUint("TOKEN1_ADDRESS");
        uint256 FEE = vm.envUint("FEE");
        uint256 SALT = vm.envUint("SALT");
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);
        PanopticFactory factory = PanopticFactory(FACTORY_ADDRESS);
        console.log("Deploying new Panoptic pool... Token0=%s, token1=%s, fee=%s, salt=%s", TOKEN0_ADDRESS, TOKEN1_ADDRESS,uint24(FEE), uint96(SALT));
        PanopticPool pool = factory.deployNewPool(TOKEN0_ADDRESS, TOKEN1_ADDRESS, uint24(FEE), uint96(SALT));
        console.log("Deployed pool to %s (token0=%s, token1=%s, fee=%s, salt=%s)", pool)

    }
}