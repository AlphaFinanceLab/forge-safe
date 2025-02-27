// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Safe} from "safe-contracts/Safe.sol";
import {Enum} from "safe-contracts/libraries/Enum.sol";

contract ExecBatchWithApprovals is Script {
    using stdJson for string;

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

    function run() public {
        string memory json = vm.readFile("./data/batch.json");
        Batch memory batch;
        batch.to = json.readAddress(".to");
        batch.value = json.readUint(".value");
        batch.data = json.readBytes(".data");
        batch.operation = Enum.Operation(json.readUint(".operation"));
        batch.safeTxGas = json.readUint(".safeTxGas");
        batch.baseGas = json.readUint(".baseGas");
        batch.gasPrice = json.readUint(".gasPrice");
        batch.gasToken = json.readAddress(".gasToken");
        batch.refundReceiver = payable(json.readAddress(".refundReceiver"));
        batch.nonce = json.readUint(".nonce");

        address safeAddress = vm.envAddress("SAFE");
        Safe SAFE = Safe(payable(safeAddress));

        // Compute transaction hash
        bytes32 txHash = SAFE.getTransactionHash(
            batch.to, batch.value, batch.data, batch.operation,
            batch.safeTxGas, batch.baseGas, batch.gasPrice,
            batch.gasToken, batch.refundReceiver, batch.nonce
        );

        // Get the sender address (the one executing the transaction)
        address sender = vm.addr(vm.envUint("PRIVATE_KEY"));
        
        // Check if the transaction has enough approvals
        uint256 threshold = SAFE.getThreshold();
        uint256 approvalCount = 0;
        
        // Count approvals by checking each owner
        address[] memory owners = SAFE.getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            if (SAFE.approvedHashes(owners[i], txHash) == 1) {
                approvalCount++;
            }
        }
        
        require(approvalCount >= threshold, "Not enough approvals");

        console2.log("Executing transaction with hash:", vm.toString(txHash));
        console2.log("Approvals:", approvalCount, "Threshold:", threshold);

        // Execute the transaction
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        bool success = SAFE.execTransaction(
            batch.to, batch.value, batch.data, batch.operation,
            batch.safeTxGas, batch.baseGas, batch.gasPrice,
            batch.gasToken, batch.refundReceiver, bytes("")
        );
        vm.stopBroadcast();

        require(success, "Transaction execution failed");
        console2.log("Transaction executed successfully");
    }
} 