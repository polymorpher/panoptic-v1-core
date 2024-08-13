// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity =0.8.18;
import "forge-std/Script.sol";
import "forge-std/console.sol";
import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
interface IUSDC {
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function configureMinter(address minter, uint256 minterAllowedAmount) external;
    function masterMinter() external view returns (address);
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address from, address recipient, uint256 amount) external;
    function approve(address spender, uint256 amount) external;
}

contract SwapUSDC is Script {
    function run() public {
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        address wethAddress = vm.envAddress("WETH_ADDRESS");
        IUniswapV3Pool pool = IUniswapV3Pool(vm.envAddress("POOL_ADDRESS"));
        uint256 ethAmount = vm.envUint("ETH_AMOUNT");
        IUSDC usdc = IUSDC(usdcAddress);
        IWETH weth = IWETH(wethAddress);
        weth.deposit{value: ethAmount}();
        address target = vm.envAddress("TARGET");
        uint256 initBalance = usdc.balanceOf(target);
        console.log("Initial USDC balance %s", initBalance);
        console.log("Swapping %s wei WETH to USDC for %s", address(weth), target);
        (uint160 price,,,,,,) = pool.slot0();
        (int256 amount0, int256 amount1) = pool.swap(target, false, int256(ethAmount), price * 2, bytes(""));
        console.log("swap done. pool diff amount0 %s", amount0);
        console.log("amount1 %s, amount1 %s", amount1);
        uint256 finalBalance = usdc.balanceOf(target);
        console.log("Final USDC balance %s", finalBalance);

    }
}