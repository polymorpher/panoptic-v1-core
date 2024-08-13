// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity =0.8.18;

import {PanopticFactory} from "@contracts/PanopticFactory.sol";
import {PanopticPool} from "@contracts/PanopticPool.sol";
import {IERC20Partial} from "@tokens/interfaces/IERC20Partial.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployPool is Script {
    uint256 internal DEPLOYER_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address internal FACTORY_ADDRESS = vm.envAddress("PANOPTIC_FACTORY_ADDRESS");
    address internal TOKEN0_ADDRESS = vm.envAddress("TOKEN0_ADDRESS");
    address internal TOKEN1_ADDRESS = vm.envAddress("TOKEN1_ADDRESS");
    address internal WETH_ADDRESS = vm.envAddress("WETH_ADDRESS");
    uint24 internal FEE = uint24(vm.envUint("FEE"));
    uint96 internal SALT = uint96(vm.envUint("SALT"));
    address deployer = vm.addr(DEPLOYER_PRIVATE_KEY);

    function run() public {

        PanopticFactory factory = PanopticFactory(FACTORY_ADDRESS);

        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);
        // first, approve factory to use both tokens, so it can pay the tokens to the pool (during position minting) on behalf of the deployer
        uint256 token0Balance = IERC20Partial(TOKEN0_ADDRESS).balanceOf(deployer);
        uint256 token1Balance = IERC20Partial(TOKEN1_ADDRESS).balanceOf(deployer);
        uint256 token0Amount = WETH_ADDRESS == TOKEN0_ADDRESS ? 5e18 : 1000e6;
        uint256 token1Amount = WETH_ADDRESS == TOKEN1_ADDRESS ? 5e18 : 1000e6;
        if (token0Balance < token0Amount) {
            console.log("ERROR: Required %s token0, got %s", token0Amount, token0Balance);
            return;
        }
        if (token1Balance < token1Amount) {
            console.log("ERROR: Required %s token1, got %s", token1Amount, token1Balance);
            return;
        }
        IERC20Partial(TOKEN0_ADDRESS).approve(address(factory), token0Amount);
        IERC20Partial(TOKEN1_ADDRESS).approve(address(factory), token1Amount);

        console.log("Deploying new Panoptic pool... Token0=%s, token1=%s, fee=%s, salt=%s", TOKEN0_ADDRESS, TOKEN1_ADDRESS);
        console.log("  - fee=%s, salt=%s", FEE, SALT);
        PanopticPool pool = factory.deployNewPool(TOKEN0_ADDRESS, TOKEN1_ADDRESS, FEE, SALT);
        console.log("Deployed pool to %s", address(pool));
        vm.stopBroadcast();

    }
}