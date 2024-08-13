#!/bin/zsh

export $(grep -v '^#' .env.swap-usdc | xargs)

forge script deploy/SwapUSDC.s.sol --rpc-url http://127.0.0.1:8545 \
  --chain-id 1 \
  --broadcast \
  --private-key ${DEPLOYER_PRIVATE_KEY} \
  -vv
