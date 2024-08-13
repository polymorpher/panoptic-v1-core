#!/bin/zsh
export $(grep -v '^#' .env.deposit-weth | xargs)

cast send ${WETH_ADDRESS} "deposit()" --value ${ETH_AMOUNT} --from ${DEPLOYER} --private-key ${DEPLOYER_PRIVATE_KEY}