// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BatchScript.sol";

// Interfaces for DeFi protocols
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    
    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
}

interface IAaveV3Pool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

/**
 * @title DeFiExample
 * @dev A script demonstrating real-world DeFi interactions using Gnosis Safe batch transactions.
 * To run: forge script script/defi_example.s.sol:DeFiExample --rpc-url $RPC_URL -vvvv
 */
contract DeFiExample is BatchScript {
    // Update this with your actual Safe address
    address constant SAFE_ADDRESS = 0x0000000000000000000000000000000000000000;
    
    // Token addresses on Ethereum Mainnet
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // DeFi protocol addresses
    address constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    
    function run() external override {
        console2.log("Building DeFi example batch for Safe:", SAFE_ADDRESS);
        console2.log("----------------------------------------");
        
        // Example 1: Approve USDC for Uniswap V3 Router
        uint256 usdcApprovalAmount = 10000 * 1e6; // 10,000 USDC (6 decimals)
        
        console2.log("1. Adding USDC approval for Uniswap V3:");
        console2.log("   Token:", USDC);
        console2.log("   Spender:", UNISWAP_V3_ROUTER);
        console2.log("   Amount:", usdcApprovalAmount);
        
        addToBatch(
            USDC,
            0,
            abi.encodeWithSelector(
                IERC20.approve.selector,
                UNISWAP_V3_ROUTER,
                usdcApprovalAmount
            )
        );
        
        // Example 2: Swap USDC for ETH on Uniswap V3
        // exactInputSingle parameters for swapping USDC to ETH
        console2.log("2. Swapping USDC for ETH on Uniswap V3");
        
        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
            tokenIn: USDC,
            tokenOut: WETH,
            fee: 3000,                  // 0.3%
            recipient: address(this),
            deadline: block.timestamp + 1800, // 30 minutes
            amountIn: 5000 * 1e6,       // 5,000 USDC
            amountOutMinimum: 0,        // 0 for example, use a real value in production
            sqrtPriceLimitX96: 0        // 0 for no limit
        });
        
        bytes memory swapCalldata = abi.encodeWithSelector(
            IUniswapV3Router.exactInputSingle.selector,
            params
        );
        
        addToBatch(
            UNISWAP_V3_ROUTER,
            0,
            swapCalldata
        );
        
        // Example 3: Supply DAI to Aave V3
        // First, approve DAI for Aave
        uint256 daiSupplyAmount = 2000 * 1e18; // 2,000 DAI (18 decimals)
        
        console2.log("3. Approving DAI for Aave V3:");
        console2.log("   Token:", DAI);
        console2.log("   Spender:", AAVE_V3_POOL);
        console2.log("   Amount:", daiSupplyAmount);
        
        addToBatch(
            DAI,
            0,
            abi.encodeWithSelector(
                IERC20.approve.selector,
                AAVE_V3_POOL,
                daiSupplyAmount
            )
        );
        
        // Then, supply DAI to Aave
        console2.log("4. Supplying DAI to Aave V3");
        
        bytes memory supplyCalldata = abi.encodeWithSelector(
            IAaveV3Pool.supply.selector,
            DAI,                   // asset
            daiSupplyAmount,       // amount
            SAFE_ADDRESS,          // onBehalfOf
            0                      // referralCode
        );
        
        addToBatch(
            AAVE_V3_POOL,
            0,
            supplyCalldata
        );
        
        // Build the batch with the Safe address
        console2.log("----------------------------------------");
        console2.log("Building batch transaction...");
        buildBatch(SAFE_ADDRESS);
    }
} 