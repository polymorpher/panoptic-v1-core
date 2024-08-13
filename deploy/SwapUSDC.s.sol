// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {CallbackLib} from "@libraries/CallbackLib.sol";
import {IUniswapV3Pool} from "univ3-core/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "univ3-core/interfaces/IUniswapV3Factory.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external;

    function transferFrom(address from, address recipient, uint256 amount) external;

    function approve(address spender, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface IUSDC is IERC20 {
    function mint(address to, uint256 amount) external;

    function configureMinter(address minter, uint256 minterAllowedAmount) external;

    function masterMinter() external view returns (address);
}

// for swapping local fake eth to usdc
contract SwapRouter {
    IUniswapV3Pool public pool;
    IUniswapV3Factory public factory;
    constructor(IUniswapV3Pool _pool){
        pool = _pool;
        factory = IUniswapV3Factory(pool.factory());
    }

    function swapEthForUsdc(address from, address to, uint256 amount) public returns (int256, int256){
        (uint160 price,,,,,,) = pool.slot0();
        bytes memory data = abi.encode(
            CallbackLib.CallbackData({ // compute by reading values from univ3pool every time
                poolFeatures: CallbackLib.PoolFeatures({
                token0: pool.token0(),
                token1: pool.token1(),
                fee: pool.fee()
            }),
                payer: from
            })
        );
        (int256 amount0, int256 amount1) = pool.swap(to, false, int256(amount), price * 2, data);
        return (amount0, amount1);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory data
    ) external {
        CallbackLib.CallbackData memory decoded = abi.decode(data, (CallbackLib.CallbackData));
        CallbackLib.validateCallback(msg.sender, address(factory), decoded.poolFeatures);
        IERC20(decoded.poolFeatures.token1).transferFrom(address(decoded.payer), address(pool), uint256(amount1Delta));
    }
}

contract SwapUSDC is Script {
    address public wethAddress = vm.envAddress("WETH_ADDRESS");
    address public usdcAddress = vm.envAddress("USDC_ADDRESS");
    IUSDC public usdc = IUSDC(usdcAddress);
    IWETH public weth = IWETH(wethAddress);
    IUniswapV3Pool public pool = IUniswapV3Pool(vm.envAddress("POOL_ADDRESS"));
    uint256 ethUnits = vm.envUint("ETH_AMOUNT");
    uint256 ethAmount = ethUnits * 1e18;
    address target = vm.envAddress("TARGET");

    function run() public {
        vm.startBroadcast(target);
        SwapRouter r = new SwapRouter(pool);
        weth.deposit{value: ethAmount}();
        weth.approve(address(r), type(uint256).max);
        uint256 initBalance = usdc.balanceOf(target);
        console.log("Initial USDC balance %s", initBalance);
        console.log("Swapping %s WETH to USDC for %s", ethUnits, target);
        (int256 amount0, int256 amount1) = r.swapEthForUsdc(target, target, ethAmount);
        console.log("swap done. pool diff amount0");
        console.logInt(amount0);
        console.log("amount1");
        console.logInt(amount1);
        uint256 finalBalance = usdc.balanceOf(target);
        console.log("Final USDC balance %s", finalBalance);
        vm.stopBroadcast();
    }


}