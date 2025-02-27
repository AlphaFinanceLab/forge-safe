// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// Sample interface for testing
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title LocalTransactionTester
 * @dev A test contract demonstrating how to locally test transactions before batching
 */
contract LocalTransactionTester is Test {
    
    // WETH address on Ethereum Mainnet
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // DAI address on Ethereum Mainnet
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
    // Structure to store transaction details
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }
    
    // Array to hold all transactions
    Transaction[] public transactions;
    
    function setUp() public {
        // Configure test to use a fork of mainnet
        vm.createSelectFork("mainnet");
    }
    
    // Add a transaction to the batch and test locally
    function addTransaction(address to, uint256 value, bytes memory data) public returns (bool success) {
        // Store the transaction
        transactions.push(Transaction({
            to: to,
            value: value,
            data: data
        }));
        
        // Execute the call locally
        (success, ) = to.call{value: value}(data);
        
        // Log the result
        if (success) {
            console.log("Transaction to", to, "succeeded");
        } else {
            console.log("Transaction to", to, "failed");
        }
        
        return success;
    }
    
    // Test function: demonstrating local testing
    function testLocalTransactionTesting() public {
        console.log("=== LOCAL TRANSACTION TESTING DEMO ===");
        
        // 1. Test a WETH balanceOf call (should succeed)
        bytes memory balanceCallData = abi.encodeWithSelector(
            IERC20.balanceOf.selector,
            address(this)
        );
        
        bool success = addTransaction(WETH, 0, balanceCallData);
        assertTrue(success, "WETH balanceOf call failed");
        
        // 2. Test a DAI transfer (should fail because we don't have any)
        bytes memory transferCallData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            address(0x1111),
            1000 * 10**18  // 1000 DAI
        );
        
        success = addTransaction(DAI, 0, transferCallData);
        assertFalse(success, "DAI transfer unexpectedly succeeded");
        
        // 3. Try a DAI approval (should succeed as it doesn't check balances)
        bytes memory approveCallData = abi.encodeWithSelector(
            IERC20.approve.selector,
            address(0x2222),
            1000 * 10**18  // 1000 DAI
        );
        
        success = addTransaction(DAI, 0, approveCallData);
        assertTrue(success, "DAI approve call failed");
        
        // In a real implementation, you'd then:
        // 1. Encode all these transactions into a Gnosis Safe batch
        // 2. Execute or schedule the batch
        
        console.log("Total transactions in batch:", transactions.length);
    }
} 