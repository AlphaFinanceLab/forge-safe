// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BatchScript.sol";

// A simple ERC20 interface for testing token approvals
interface IERC20Test {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title TestBatch
 * @dev A simple script to test the Gnosis Safe batch functionality with a basic test transaction.
 * To run: forge script script/testbatch.s.sol:TestBatch --rpc-url $RPC_URL -vvvv
 */
contract TestBatch is BatchScript {
    // Update this with your actual Safe address for testing
    address constant TEST_SAFE_ADDRESS = 0x0000000000000000000000000000000000000000;
    
    
    function run() external override {
        // Use a test Safe address (replace with your actual Safe for real testing)
        address safeAddress = TEST_SAFE_ADDRESS;
        
        console2.log("Building test batch for Safe:", safeAddress);
        console2.log("----------------------------------------");
        
        // Example 1: Simple ETH transfer
        // Sends a small amount of ETH (0.001 ETH) to a test address
        address testRecipient = 0x0000000000000000000000000000000000000001;
        uint256 testAmount = 0.001 ether; // 0.001 ETH in wei
        
        console2.log("Adding ETH transfer:");
        console2.log("  To:", testRecipient);
        console2.log("  Amount:", testAmount);
        
        addToBatch(
            testRecipient,
            testAmount,
            "" // Empty call data for a simple ETH transfer
        );
        
        // Example 2: Token approval (using DAI as an example)
        // Note: This is just for demonstration, replace with real token addresses
        address daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI on Ethereum Mainnet
        address testSpender = 0x0000000000000000000000000000000000000002;
        uint256 approvalAmount = 1000 * 1e18; // 1000 DAI (with 18 decimals)
        
        console2.log("Adding token approval:");
        console2.log("  Token:", daiToken);
        console2.log("  Spender:", testSpender);
        console2.log("  Amount:", approvalAmount);
        
        addToBatch(
            daiToken,
            0,
            abi.encodeWithSelector(
                IERC20Test.approve.selector,
                testSpender,
                approvalAmount
            )
        );
        
        // Build the batch with the Safe address
        console2.log("----------------------------------------");
        console2.log("Building batch transaction...");
        buildBatch(safeAddress);
    }
}
