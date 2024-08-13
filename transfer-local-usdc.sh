#!/bin/zsh

export $(grep -v '^#' .env.transfer-usdc | xargs)
export ETH_RPC_URL=http://127.0.0.1:8545

function echoed() {
    echo
    echo ">" "$@"
    "$@"
}

echoed cast rpc anvil_impersonateAccount $IMPERSONATE_TARGET
echoed cast send $USDC_ADDRESS --unlocked --from $IMPERSONATE_TARGET "approve(address,uint256)" $TARGET 1000000000
echoed cast call $USDC_ADDRESS "balanceOf(address)(uint256)" $IMPERSONATE_TARGET
echoed cast call $USDC_ADDRESS "allowance(address,address)(uint256)" $IMPERSONATE_TARGET $TARGET
echoed cast send $USDC_ADDRESS --unlocked --from $TARGET "transferFrom(address,address,uint256)" $IMPERSONATE_TARGET $TARGET 100000
echoed cast rpc anvil_stopImpersonatingAccount $IMPERSONATE_TARGET