#!/bin/zsh

export $(grep -v '^#' .env | xargs)
forge script deploy/DeployProtocol.s.sol --rpc-url https://api.harmony.one \
  --chain-id 1666600000 \
  --gas-price 100000000000 \
  --legacy \
  --broadcast \
  --private-key ${DEPLOYER_PRIVATE_KEY} \
  -vv \
  --resume

