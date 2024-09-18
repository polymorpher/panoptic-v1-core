#!/bin/zsh
export $(grep -v '^#' .env.deploy-pool | xargs)

cast code ${PANOPTIC_FACTORY_ADDRESS} --rpc-url http://127.0.0.1:8545
