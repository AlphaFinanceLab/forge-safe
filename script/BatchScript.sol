// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "safe-contracts/Safe.sol";
import "safe-contracts/libraries/Enum.sol";

/// @title Interface for the MultiSend contract
interface IMultiSend {
    function multiSend(bytes memory transactions) external payable;
}

/// @title BatchScript - A script for creating and executing Gnosis Safe batch transactions
/// @notice This contract provides utilities for building batch transactions with on-chain approvals
contract BatchScript is Script {
    // NOTE: This is the MultiSend v1.4.1 contract address for most chains. Modify if using a custom deployment.
    address constant SAFE_MULTISEND_ADDRESS = 0x38869bf66a61cF6bDB996A6aE40D5853Fd43B526;
    
    /// @notice Array to store encoded transactions for the batch
    bytes[] internal encodedTxns;

    /// @notice Struct representing a Safe batch transaction
    struct Batch {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address payable refundReceiver;
        uint256 nonce;
    }

    /// @notice Add a standard call operation to the batch
    /// @param to The target address for the transaction
    /// @param value The amount of ETH to send
    /// @param data The calldata for the transaction
    function addToBatch(address to, uint256 value, bytes memory data) public {
        bytes memory encodedTxn = abi.encodePacked(
            uint8(0), // operation (0 for CALL)
            to,
            value,
            data.length,
            data
        );
        encodedTxns.push(encodedTxn);
    }

    /// @notice Add a delegate call operation to the batch
    /// @param to The target address for the delegate call
    /// @param data The calldata for the transaction
    function addDelegateCallToBatch(address to, bytes memory data) public {
        bytes memory encodedTxn = abi.encodePacked(
            uint8(1), // operation (1 for DELEGATECALL)
            to,
            uint256(0), // value must be 0 for delegatecall
            data.length,
            data
        );
        encodedTxns.push(encodedTxn);
    }

    /// @notice Build the batch transaction and save to JSON
    /// @param safe_ The address of the Gnosis Safe
    function buildBatch(address safe_) internal {
        require(safe_ != address(0), "Safe address cannot be zero");
        
        Safe SAFE = Safe(payable(safe_));
        uint256 nonce = SAFE.nonce();
        Batch memory batch = _createBatch(nonce);

        // Serialize batch to JSON
        string memory json = "";
        json = vm.serializeAddress("batch", "to", batch.to);
        json = vm.serializeUint("batch", "value", batch.value);
        json = vm.serializeBytes("batch", "data", batch.data);
        json = vm.serializeUint("batch", "operation", uint8(batch.operation));
        json = vm.serializeUint("batch", "safeTxGas", batch.safeTxGas);
        json = vm.serializeUint("batch", "baseGas", batch.baseGas);
        json = vm.serializeUint("batch", "gasPrice", batch.gasPrice);
        json = vm.serializeAddress("batch", "gasToken", batch.gasToken);
        json = vm.serializeAddress("batch", "refundReceiver", batch.refundReceiver);
        json = vm.serializeUint("batch", "nonce", batch.nonce);
        vm.writeJson(json, "./data/batch.json");

        // Compute and output transaction hash
        bytes32 txHash = SAFE.getTransactionHash(
            batch.to, batch.value, batch.data, batch.operation,
            batch.safeTxGas, batch.baseGas, batch.gasPrice,
            batch.gasToken, batch.refundReceiver, batch.nonce
        );
        console2.log("Transaction hash to approve:", vm.toString(txHash));
    }

    /// @notice Create a batch transaction from collected transactions
    /// @param nonce The Safe's current nonce
    /// @return batch The constructed batch transaction
    function _createBatch(uint256 nonce) private view returns (Batch memory batch) {
        batch.to = SAFE_MULTISEND_ADDRESS;
        batch.value = 0;
        batch.operation = Enum.Operation.DelegateCall;
        bytes memory data;
        for (uint256 i; i < encodedTxns.length; ++i) {
            data = bytes.concat(data, encodedTxns[i]);
        }
        batch.data = abi.encodeWithSelector(IMultiSend.multiSend.selector, data);
        batch.safeTxGas = 0;
        batch.baseGas = 0;
        batch.gasPrice = 0;
        batch.gasToken = address(0);
        batch.refundReceiver = payable(address(0));
        batch.nonce = nonce;
    }

    /// @notice Template run function - override this in derived contracts
    /// @dev Implement this function with your specific transactions
    function run() external virtual {
        // Replace with your actual Safe address
        address safeAddress = 0x0000000000000000000000000000000000000000;
        
        // Add your transactions to the batch
        // Example: addToBatch(targetAddress, ethValue, callData);
        
        // Build and output the batch transaction
        buildBatch(safeAddress);
    }
} 