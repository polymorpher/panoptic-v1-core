#!/bin/zsh

export $(grep -v '^#' .env | xargs)
forge script deploy/DeployProtocol.s.sol --rpc-url http://127.0.0.1:8545 \
  --chain-id 31337 \
  --broadcast \
  --private-key ${DEPLOYER_PRIVATE_KEY} \
  -vv

