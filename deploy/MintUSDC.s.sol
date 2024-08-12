// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity =0.8.18;
import "forge-std/Script.sol";
import "forge-std/console.sol";


interface IUSDC {
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function configureMinter(address minter, uint256 minterAllowedAmount) external;
    function masterMinter() external view returns (address);
}

contract USDCTest is Script {
    function run() public {
        address USDC_ADDRESS = vm.envAddress("USDC_ADDRESS");
        IUSDC usdc = IUSDC(USDC_ADDRESS);
        vm.prank(usdc.masterMinter());
        address TARGET = vm.envAddress("TARGET");
        usdc.configureMinter(address(this), type(uint256).max);
        usdc.mint(TARGET, 1000e6);
    }
}