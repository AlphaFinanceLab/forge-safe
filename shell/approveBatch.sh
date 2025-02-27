#!/bin/bash

source .env

cast send --private-key $PRIVATE_KEY $SAFE_ADDRESS "approveHash(bytes32)" $TX_HASH --rpc-url $RPC_URL