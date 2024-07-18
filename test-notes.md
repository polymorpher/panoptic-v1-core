## Code version

The note is based on commit https://github.com/polymorpher/panoptic-v1-core/commit/02cd20d23698f9ae62d6d51262f7043be4146b6c (the HEAD of main branch from https://github.com/panoptic-labs/panoptic-v1-core as of 7/18/2024)

## Running a test

Running all tests

```
forge test
```

Running selected tests (useful for debugging failures)

```
forge test --match-test <....>
```

With debugging traces turned on (granularity can be decreased by decreasing the number of `v`)

```
forge test --match-test <....> -vvvvv
```

Read more about tests and command line options

Tests: https://book.getfoundry.sh/forge/tests
Options: https://book.getfoundry.sh/reference/forge/forge-test

## Test failures in original code

Below is a sample output from a single test run. Due to randomized nature of the tests, different tests may fail across different runs.

Read more about randomized testing: https://book.getfoundry.sh/forge/fuzz-testing

```
Ran 16 test suites in 425.21s (1849.06s CPU time): 356 tests passed, 5 failed, 0 skipped (361 total tests)

Failing tests:
Encountered 1 failing test in test/foundry/core/CollateralTracker.t.sol:CollateralTrackerTest
[FAIL. Reason: Failed contract call; counterexample: calldata=0x args=[]] test_Success_collateralCheck_ITMputSpread(uint256,uint128,uint256,uint256,int256,int256,int24,uint256) (runs: 1, μ: 123277950, ~: 123277950)

Encountered 4 failing tests in test/foundry/core/PanopticFactory.t.sol:PanopticFactoryTest
[FAIL. Reason: TransferFailed()] test_Fail_deployExistingPool() (gas: 1657139)
[FAIL. Reason: assertion failed] test_Fail_deployNewPool_UnsupportedPool() (gas: 558205)
[FAIL. Reason: TransferFailed(); counterexample: calldata=0x53cf803a000000000000000000000000000000000000000000000000000000000000ce88000000000000000000000000000000000000000000010b485f99c00d07534597 args=[52872 [5.287e4], 1262206905247769589663127 [1.262e24]]] test_Success_deployNewPool(uint256,uint96) (runs: 0, μ: 0, ~: 0)
[FAIL. Reason: TransferFailed(); counterexample: calldata=0xc8f0c8ab000000000000000000000000000000000000000000000000000000000000ce88000000000000000000000000000000000000000000010b485f99c00d07534597fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe args=[52872 [5.287e4], 1262206905247769589663127 [1.262e24], 115792089237316195423570985008687907853269984665640564039457584007913129639934 [1.157e77]]] test_Success_mineTargetRarity(uint256,uint96,uint256) (runs: 0, μ: 0, ~: 0)

Encountered a total of 5 failing tests, 356 tests succeeded
```

## Analysis

`test_Fail_deployExistingPool`, `test_Fail_deployNewPool_UnsupportedPool`, `test_Success_deployNewPool`, `test_Success_mineTargetRarity` are simple tests designed to cover pool setup and configurations, under `PanopticFactory.t.sol`.

`test_Success_collateralCheck_ITMputSpread` is a complex test covering the core functionalities of options trading and collateral tracking, under `CollateralTracker.t.sol`.

We begin with taking a deeper look of `test_Fail_deployExistingPool`. Running the selected test with debug trace turned on, we can observe that the failure is related to transferring some ERC-20 tokens to test accounts. For some reasons, the account is blacklisted.

```
panoptic-v1-core %  forge test --match-test test_Fail_deployExistingPool -vvvvv

Ran 1 test for test/foundry/core/PanopticFactory.t.sol:PanopticFactoryTest
[FAIL. Reason: TransferFailed()] test_Fail_deployExistingPool() (gas: 1657139)
Logs:
  Error: a == b not satisfied [uint]
        Left: 57896044618658097711785492504343953926634992332820282019728792003956564819967
       Right: 115792089237316195423570985008687907853269984665640564039457584007913129639935

Traces:
  [12112275] PanopticFactoryTest::setUp()
    ├─ [4280851] → new PanopticPool@0x2e234DAe75C793f67A35089C9d99245E1C58470b
    │   └─ ← [Return] 21378 bytes of code
    ├─ [4617392] → new CollateralTracker@0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
    │   └─ ← [Return] 23060 bytes of code
    ├─ [3079960] → new PanopticFactoryHarness@0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9
    │   ├─ emit OwnerChanged(oldOwner: 0x0000000000000000000000000000000000000000, newOwner: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496])
    │   └─ ← [Return] 15026 bytes of code
    └─ ← [Stop]

  [1497939] PanopticFactoryTest::test_Fail_deployExistingPool()
    ├─ [266] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::token0() [staticcall]
    │   └─ ← [Return] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    ├─ [308] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::token1() [staticcall]
    │   └─ ← [Return] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    ├─ [251] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::fee() [staticcall]
    │   └─ ← [Return] 500
    ├─ [279] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::tickSpacing() [staticcall]
    │   └─ ← [Return] 10
    ├─ [9839] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   ├─ [2553] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [delegatecall]
    │   │   └─ ← [Return] 0
    │   └─ ← [Return] 0
    ├─ [0] VM::record()
    │   └─ ← [Return]
    ├─ [1339] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   ├─ [553] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [delegatecall]
    │   │   └─ ← [Return] 0
    │   └─ ← [Return] 0
    ├─ [0] VM::accesses(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
    │   └─ ← [Return] [0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b, 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3, 0xea80dd88ed2c8da1b3cfa53b6b2568ae58fe83d484d0c01324a62ba1aa9ffdac], []
    ├─ [0] VM::load(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b) [staticcall]
    │   └─ ← [Return] 0x000000000000000000000000807a96288a1a408dbc13de2b1d087d10356395d2
    ├─ [0] VM::store(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b, 0x1337000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [1339] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   ├─ [553] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [delegatecall]
    │   │   └─ ← [Return] 0
    │   └─ ← [Return] 0
    ├─ [0] VM::store(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b, 0x000000000000000000000000807a96288a1a408dbc13de2b1d087d10356395d2)
    │   └─ ← [Return]
    ├─ [0] VM::load(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000043506849d7c04f9138d1a2050bbf3a0c054402dd
    ├─ [0] VM::store(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3, 0x1337000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [3283] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   ├─ [0] 0x0000000000000000000000000000000000000000::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [delegatecall]
    │   │   └─ ← [Stop]
    │   └─ ← [Return]
    ├─ [0] VM::store(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3, 0x00000000000000000000000043506849d7c04f9138d1a2050bbf3a0c054402dd)
    │   └─ ← [Return]
    ├─ [0] VM::load(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xea80dd88ed2c8da1b3cfa53b6b2568ae58fe83d484d0c01324a62ba1aa9ffdac) [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    ├─ emit WARNING_UninitedSlot(who: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, slot: 106068891970248696789493712859882542862066930050875226902812495036911416507820 [1.06e77])
    ├─ [0] VM::store(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xea80dd88ed2c8da1b3cfa53b6b2568ae58fe83d484d0c01324a62ba1aa9ffdac, 0x1337000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [1339] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   ├─ [553] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [delegatecall]
    │   │   └─ ← [Return] 8691120711644872517220240406154416179355393288731169655000180904158396678144 [8.691e75]
    │   └─ ← [Return] 8691120711644872517220240406154416179355393288731169655000180904158396678144 [8.691e75]
    ├─ emit SlotFound(who: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, fsig: 0x70a0823100000000000000000000000000000000000000000000000000000000, keysHash: 0x5ff10565516c110180bb9cc111cdbc2b0a68e09ff7fac17290373c3aa4a1bb03, slot: 106068891970248696789493712859882542862066930050875226902812495036911416507820 [1.06e77])
    ├─ [0] VM::store(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xea80dd88ed2c8da1b3cfa53b6b2568ae58fe83d484d0c01324a62ba1aa9ffdac, 0x0000000000000000000000000000000000000000000000000000000000000000)
    │   └─ ← [Return]
    ├─ [1339] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   ├─ [553] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [delegatecall]
    │   │   └─ ← [Return] 0
    │   └─ ← [Return] 0
    ├─ [0] VM::load(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xea80dd88ed2c8da1b3cfa53b6b2568ae58fe83d484d0c01324a62ba1aa9ffdac) [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    ├─ [0] VM::store(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xea80dd88ed2c8da1b3cfa53b6b2568ae58fe83d484d0c01324a62ba1aa9ffdac, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
    │   └─ ← [Return]
    ├─ [2534] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::record()
    │   └─ ← [Return]
    ├─ [534] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::accesses(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    │   └─ ← [Return] [0x1da434b76eba4736d6e760bfd78cbf883a0776ee1666a9157f99ab1b97923a3c], []
    ├─ [0] VM::load(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x1da434b76eba4736d6e760bfd78cbf883a0776ee1666a9157f99ab1b97923a3c) [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    ├─ emit WARNING_UninitedSlot(who: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, slot: 13407199363679635973052879518465057167389910613330280238043615909335847287356 [1.34e76])
    ├─ emit SlotFound(who: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, fsig: 0x70a0823100000000000000000000000000000000000000000000000000000000, keysHash: 0x5ff10565516c110180bb9cc111cdbc2b0a68e09ff7fac17290373c3aa4a1bb03, slot: 13407199363679635973052879518465057167389910613330280238043615909335847287356 [1.34e76])
    ├─ [534] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   └─ ← [Return] 0
    ├─ [0] VM::load(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x1da434b76eba4736d6e760bfd78cbf883a0776ee1666a9157f99ab1b97923a3c) [staticcall]
    │   └─ ← [Return] 0x0000000000000000000000000000000000000000000000000000000000000000
    ├─ [0] VM::store(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x1da434b76eba4736d6e760bfd78cbf883a0776ee1666a9157f99ab1b97923a3c, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
    │   └─ ← [Return]
    ├─ [1339] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   ├─ [553] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [delegatecall]
    │   │   └─ ← [Return] 57896044618658097711785492504343953926634992332820282019728792003956564819967 [5.789e76]
    │   └─ ← [Return] 57896044618658097711785492504343953926634992332820282019728792003956564819967 [5.789e76]
    ├─ emit log(val: "Error: a == b not satisfied [uint]")
    ├─ emit log_named_uint(key: "      Left", val: 57896044618658097711785492504343953926634992332820282019728792003956564819967 [5.789e76])
    ├─ emit log_named_uint(key: "     Right", val: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    ├─ [0] VM::store(VM: [0x7109709ECfa91a80626fF3989D68f67F5b1DD12D], 0x6661696c65640000000000000000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000000000000000000000000001)
    │   └─ ← [Return]
    ├─ [534] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::balanceOf(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496]) [staticcall]
    │   └─ ← [Return] 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]
    ├─ [27462] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::approve(PanopticFactoryHarness: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   ├─ [26673] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::approve(PanopticFactoryHarness: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]) [delegatecall]
    │   │   ├─ emit Approval(owner: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], spender: PanopticFactoryHarness: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   └─ ← [Return] true
    │   └─ ← [Return] true
    ├─ [24420] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::approve(PanopticFactoryHarness: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   ├─ emit Approval(owner: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], spender: PanopticFactoryHarness: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   └─ ← [Return] true
    ├─ [25462] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::approve(SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   ├─ [24673] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::approve(SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]) [delegatecall]
    │   │   ├─ emit Approval(owner: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], spender: SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   └─ ← [Return] true
    │   └─ ← [Return] true
    ├─ [24420] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::approve(SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   ├─ emit Approval(owner: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], spender: SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   └─ ← [Return] true
    ├─ [25462] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::approve(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   ├─ [24673] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::approve(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]) [delegatecall]
    │   │   ├─ emit Approval(owner: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], spender: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   └─ ← [Return] true
    │   └─ ← [Return] true
    ├─ [24420] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::approve(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   ├─ emit Approval(owner: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], spender: PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   └─ ← [Return] true
    ├─ [1002756] PanopticFactoryHarness::deployNewPool(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 500, 1721324339 [1.721e9])
    │   ├─ [2666] 0x1F98431c8aD98523631AE4a59f267346ea31F984::getPool(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 500) [staticcall]
    │   │   └─ ← [Return] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640
    │   ├─ [279] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::tickSpacing() [staticcall]
    │   │   └─ ← [Return] 10
    │   ├─ [9031] → new <unknown>@0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7
    │   │   └─ ← [Return] 45 bytes of code
    │   ├─ [9031] → new <unknown>@0xDD4c722d1614128933d6DC7EFA50A6913e804E12
    │   │   └─ ← [Return] 45 bytes of code
    │   ├─ [228129] 0xDD4c722d1614128933d6DC7EFA50A6913e804E12::startToken(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7)
    │   │   ├─ [225448] CollateralTracker::startToken(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7) [delegatecall]
    │   │   │   ├─ [266] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::token0() [staticcall]
    │   │   │   │   └─ ← [Return] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    │   │   │   ├─ [308] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::token1() [staticcall]
    │   │   │   │   └─ ← [Return] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    │   │   │   ├─ [279] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::tickSpacing() [staticcall]
    │   │   │   │   └─ ← [Return] 10
    │   │   │   ├─ [251] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::fee() [staticcall]
    │   │   │   │   └─ ← [Return] 500
    │   │   │   └─ ← [Stop]
    │   │   └─ ← [Return]
    │   ├─ [9031] → new <unknown>@0x7ff9C67c93D9f7318219faacB5c619a773AFeF6A
    │   │   └─ ← [Return] 45 bytes of code
    │   ├─ [225629] 0x7ff9C67c93D9f7318219faacB5c619a773AFeF6A::startToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7)
    │   │   ├─ [225448] CollateralTracker::startToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7) [delegatecall]
    │   │   │   ├─ [266] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::token0() [staticcall]
    │   │   │   │   └─ ← [Return] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    │   │   │   ├─ [308] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::token1() [staticcall]
    │   │   │   │   └─ ← [Return] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    │   │   │   ├─ [279] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::tickSpacing() [staticcall]
    │   │   │   │   └─ ← [Return] 10
    │   │   │   ├─ [251] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::fee() [staticcall]
    │   │   │   │   └─ ← [Return] 500
    │   │   │   └─ ← [Stop]
    │   │   └─ ← [Return]
    │   ├─ [2696] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::slot0() [staticcall]
    │   │   └─ ← [Return] 1354800995080852832903570189863457 [1.354e33], 194946 [1.949e5], 478, 723, 723, 0, true
    │   ├─ [197229] 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7::startPool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 10, 194946 [1.949e5], 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xDD4c722d1614128933d6DC7EFA50A6913e804E12, 0x7ff9C67c93D9f7318219faacB5c619a773AFeF6A)
    │   │   ├─ [194524] PanopticPool::startPool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 10, 194946 [1.949e5], 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0xDD4c722d1614128933d6DC7EFA50A6913e804E12, 0x7ff9C67c93D9f7318219faacB5c619a773AFeF6A) [delegatecall]
    │   │   │   ├─ [101907] InteractionHelper::dbfff1ca(0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f000000000000000000000000dd4c722d1614128933d6dc7efa50a6913e804e120000000000000000000000007ff9c67c93d9f7318219faacb5c619a773afef6a000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2) [delegatecall]
    │   │   │   │   ├─ [25462] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::approve(SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   │   │   │   ├─ [24673] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::approve(SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]) [delegatecall]
    │   │   │   │   │   │   ├─ emit Approval(owner: 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7, spender: SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   │   │   │   │   └─ ← [Return] true
    │   │   │   │   │   └─ ← [Return] true
    │   │   │   │   ├─ [24420] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::approve(SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   │   │   │   ├─ emit Approval(owner: 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7, spender: SemiFungiblePositionManager: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   │   │   │   └─ ← [Return] true
    │   │   │   │   ├─ [25462] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::approve(0xDD4c722d1614128933d6DC7EFA50A6913e804E12, 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   │   │   │   ├─ [24673] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::approve(0xDD4c722d1614128933d6DC7EFA50A6913e804E12, 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77]) [delegatecall]
    │   │   │   │   │   │   ├─ emit Approval(owner: 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7, spender: 0xDD4c722d1614128933d6DC7EFA50A6913e804E12, amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   │   │   │   │   └─ ← [Return] true
    │   │   │   │   │   └─ ← [Return] true
    │   │   │   │   ├─ [24420] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::approve(0x7ff9C67c93D9f7318219faacB5c619a773AFeF6A, 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   │   │   │   ├─ emit Approval(owner: 0x41d50012F88Da1506631DDCA9498FdBA20b7c6b7, spender: 0x7ff9C67c93D9f7318219faacB5c619a773AFeF6A, amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935 [1.157e77])
    │   │   │   │   │   └─ ← [Return] true
    │   │   │   │   └─ ← [Stop]
    │   │   │   └─ ← [Stop]
    │   │   └─ ← [Return]
    │   ├─ [47633] SemiFungiblePositionManager::initializeAMMPool(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 500)
    │   │   ├─ [666] 0x1F98431c8aD98523631AE4a59f267346ea31F984::getPool(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 500) [staticcall]
    │   │   │   └─ ← [Return] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640
    │   │   ├─ emit PoolInitialized(uniswapPool: 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640)
    │   │   └─ ← [Stop]
    │   ├─ [696] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::slot0() [staticcall]
    │   │   └─ ← [Return] 1354800995080852832903570189863457 [1.354e33], 194946 [1.949e5], 478, 723, 723, 0, true
    │   ├─ [134256] 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640::mint(PanopticFactoryHarness: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], -887270 [-8.872e5], 887270 [8.872e5], 5847955736815 [5.847e12], 0x000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000000000000000001f40000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496)
    │   │   ├─ [3339] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::balanceOf(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640) [staticcall]
    │   │   │   ├─ [2553] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::balanceOf(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640) [delegatecall]
    │   │   │   │   └─ ← [Return] 88910308296500 [8.891e13]
    │   │   │   └─ ← [Return] 88910308296500 [8.891e13]
    │   │   ├─ [2534] 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2::balanceOf(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640) [staticcall]
    │   │   │   └─ ← [Return] 22768829621848083051585 [2.276e22]
    │   │   ├─ [5978] PanopticFactoryHarness::uniswapV3MintCallback(341985863 [3.419e8], 99999999999991293 [9.999e16], 0x000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000000000000000001f40000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496)
    │   │   │   ├─ [3875] 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48::transferFrom(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 341985863 [3.419e8])
    │   │   │   │   ├─ [3064] 0x43506849D7C04F9138D1A2050bbF3A0c054402dd::transferFrom(PanopticFactoryTest: [0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496], 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, 341985863 [3.419e8]) [delegatecall]
    │   │   │   │   │   └─ ← [Revert] revert: Blacklistable: account is blacklisted
    │   │   │   │   └─ ← [Revert] revert: Blacklistable: account is blacklisted
    │   │   │   └─ ← [Revert] TransferFailed()
    │   │   └─ ← [Revert] TransferFailed()
    │   └─ ← [Revert] TransferFailed()
    └─ ← [Revert] TransferFailed()

Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 11.77s (8.85s CPU time)

Ran 1 test suite in 12.92s (11.77s CPU time): 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/foundry/core/PanopticFactory.t.sol:PanopticFactoryTest
[FAIL. Reason: TransferFailed()] test_Fail_deployExistingPool() (gas: 1657139)

Encountered a total of 1 failing tests, 0 tests succeeded

```

The innermost errors are thrown from notable ERC-20 token addresses: `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` and `0x43506849D7C04F9138D1A2050bbF3A0c054402dd`, which are USDC token (proxy contract) and their respective implementation contract.

The code for the implementation contract can be looked up on Etherscan: https://etherscan.io/address/0x43506849d7c04f9138d1a2050bbf3a0c054402dd#code. The contract FiatTokenV2_2 inherits from its previous versions. The blacklisting logic can be traced and found in FiatTokenV1:

```
contract FiatTokenV1 is AbstractFiatTokenV1, Ownable, Pausable, Blacklistable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    address public masterMinter;
    bool internal initialized;

    /// @dev A mapping that stores the balance and blacklist states for a given address.
    /// The first bit defines whether the address is blacklisted (1 if blacklisted, 0 otherwise).
    /// The last 255 bits define the balance for the address.
    mapping(address => uint256) internal balanceAndBlacklistStates;

    ...


     /**
     * @inheritdoc Blacklistable
     */
    function _blacklist(address _account) internal override {
        _setBlacklistState(_account, true);
    }

    /**
     * @inheritdoc Blacklistable
     */
    function _unBlacklist(address _account) internal override {
        _setBlacklistState(_account, false);
    }

```

And in the latest implementation (FiatTokenV2_2), the blacklist bit and balance are used as the following manner, consistent with the code comments above:

```
    /**
     * @dev Helper method that sets the blacklist state of an account on balanceAndBlacklistStates.
     * If _shouldBlacklist is true, we apply a (1 << 255) bitmask with an OR operation on the
     * account's balanceAndBlacklistState. This flips the high bit for the account to 1,
     * indicating that the account is blacklisted.
     *
     * If _shouldBlacklist if false, we reset the account's balanceAndBlacklistStates to their
     * balances. This clears the high bit for the account, indicating that the account is unblacklisted.
     * @param _account         The address of the account.
     * @param _shouldBlacklist True if the account should be blacklisted, false if the account should be unblacklisted.
     */
    function _setBlacklistState(address _account, bool _shouldBlacklist)
        internal
        override
    {
        balanceAndBlacklistStates[_account] = _shouldBlacklist
            ? balanceAndBlacklistStates[_account] | (1 << 255)
            : _balanceOf(_account);
    }


    /**
     * @dev Helper method that sets the balance of an account on balanceAndBlacklistStates.
     * Since balances are stored in the last 255 bits of the balanceAndBlacklistStates value,
     * we need to ensure that the updated balance does not exceed (2^255 - 1).
     * Since blacklisted accounts' balances cannot be updated, the method will also
     * revert if the account is blacklisted
     * @param _account The address of the account.
     * @param _balance The new fiat token balance of the account (max: (2^255 - 1)).
     */
    function _setBalance(address _account, uint256 _balance) internal override {
        require(
            _balance <= ((1 << 255) - 1),
            "FiatTokenV2_2: Balance exceeds (2^255 - 1)"
        );
        require(
            !_isBlacklisted(_account),
            "FiatTokenV2_2: Account is blacklisted"
        );

        balanceAndBlacklistStates[_account] = _balance;
    }

    /**
     * @inheritdoc Blacklistable
     */
    function _isBlacklisted(address _account)
        internal
        override
        view
        returns (bool)
    {
        return balanceAndBlacklistStates[_account] >> 255 == 1;
    }

    /**
     * @dev Helper method to obtain the balance of an account. Since balances
     * are stored in the last 255 bits of the balanceAndBlacklistStates value,
     * we apply a ((1 << 255) - 1) bit bitmask with an AND operation on the
     * balanceAndBlacklistState to obtain the balance.
     * @param _account  The address of the account.
     * @return          The fiat token balance of the account.
     */
    function _balanceOf(address _account)
        internal
        override
        view
        returns (uint256)
    {
        return balanceAndBlacklistStates[_account] & ((1 << 255) - 1);
    }
```

In simpler terms, an account is blacklisted when its account balance's 256-bit storage slot's leading bit is 1. Only the remaining 255 bits represents the balance of the account.

However, tracing back to how pools and test states are initialized for each test, we find the test accounts are initialized with a token amount that has all 256-bit set to 1: https://github.com/panoptic-labs/panoptic-v1-core/blob/02cd20d23698f9ae62d6d51262f7043be4146b6c/test/foundry/core/PanopticFactory.t.sol#L92

From PanopticFactory.t.sol:

```
    function _initalizeWorldState(IUniswapV3Pool _pool) internal {
        // initalize current pool we are deploying
        pool = _pool;
        token0 = _pool.token0();
        token1 = _pool.token1();
        fee = _pool.fee();
        tickSpacing = _pool.tickSpacing();

        // give test contract a sufficient amount of tokens to deploy a new pool
        deal(token0, address(this), INITIAL_MOCK_TOKENS);
        deal(token1, address(this), INITIAL_MOCK_TOKENS);
        assertEq(IERC20Partial(token0).balanceOf(address(this)), INITIAL_MOCK_TOKENS);
        assertEq(IERC20Partial(token1).balanceOf(address(this)), INITIAL_MOCK_TOKENS);

        // approve factory to move tokens, on behalf of the test contract
        IERC20Partial(token0).approve(address(panopticFactory), INITIAL_MOCK_TOKENS);
        IERC20Partial(token1).approve(address(panopticFactory), INITIAL_MOCK_TOKENS);

        // approve sfpm to move tokens, on behalf of the test contract
        IERC20Partial(token0).approve(address(sfpm), INITIAL_MOCK_TOKENS);
        IERC20Partial(token1).approve(address(sfpm), INITIAL_MOCK_TOKENS);

        // approve self
        IERC20Partial(token0).approve(address(this), INITIAL_MOCK_TOKENS);
        IERC20Partial(token1).approve(address(this), INITIAL_MOCK_TOKENS);
    }
```

Where `INITIAL_MOCK_TOKENS` is defined in early part of the contract:

```
        uint256 constant INITIAL_MOCK_TOKENS = type(uint256).max;
```

## Fix and verification

To fix the issue, we just need to make sure the leading bit of the balance is not used, by removing that from INITIAL_MOCK_TOKENS:

```
        uint256 constant INITIAL_MOCK_TOKENS = type(uint256).max >> 1;
```

Re-run the tests, we can verify they now all pass:

```
forge test --match-test test_Fail_deployExistingPool -vvvvv
forge test --match-test test_Fail_deployNewPool_UnsupportedPool -vvvvv
forge test --match-test test_Success_deployNewPool -vvvvv
forge test --match-test test_Success_mineTargetRarity -vvvvv

## This test may take much longer than the other
forge test --match-test test_Success_collateralCheck_ITMputSpread -vvvvv
```

Verify again by running the entire test suite (since other tests may fail due to randomized nature of the tests)

```
panoptic-v1-core % forge test
[⠊] Compiling...
No files changed, compilation skipped

Ran 7 tests for test/foundry/types/LiquidityChunk.t.sol:LiquidityChunkTest
[PASS] test_Success_AddLiq(uint128) (runs: 7, μ: 6727, ~: 6727)
[PASS] test_Success_AddTicksLiquidity(int24,int24,uint128) (runs: 7, μ: 9101, ~: 9101)
[PASS] test_Success_TickLower(int24) (runs: 7, μ: 6759, ~: 6759)
[PASS] test_Success_TickUpper(int24) (runs: 7, μ: 6813, ~: 6813)
[PASS] test_Success_copyTickRange(int24,int24,uint128) (runs: 7, μ: 12991, ~: 12991)
[PASS] test_Success_updateTickLower(int24,int24) (runs: 7, μ: 8878, ~: 8878)
[PASS] test_Success_updateTickUpper(int24,int24) (runs: 7, μ: 8887, ~: 8887)
Suite result: ok. 7 passed; 0 failed; 0 skipped; finished in 1.46s (10.22ms CPU time)

Ran 3 tests for test/foundry/libraries/PositionAmountsTest.sol:PositionAmountsTest
[PASS] test_Success_getLiquidityForAmountAtRatio_OTMAbove() (gas: 4864)
[PASS] test_Success_getLiquidityForAmountAtRatio_OTMBelow() (gas: 5137)
[PASS] test_Success_getLiquidityForAmountAtRatio_OTMBetween(int256,int256,int256,uint256) (runs: 7, μ: 29130, ~: 29252)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 123.54ms (123.07ms CPU time)

Ran 23 tests for test/foundry/types/LeftRight.t.sol:LeftRightTest
[PASS] test_Fail_DivInts() (gas: 8724)
[PASS] test_Fail_toRightSlot(int128) (runs: 7, μ: 15214, ~: 14950)
[PASS] test_Success_AddInts(int128,int128,int128,int128) (runs: 7, μ: 22634, ~: 22554)
[PASS] test_Success_AddUintInt(uint128,uint128,int128,int128) (runs: 7, μ: 14770, ~: 14662)
[PASS] test_Success_AddUints(uint128,uint128,uint128,uint128) (runs: 7, μ: 22480, ~: 22406)
[PASS] test_Success_BothSlots_int256(int128,int128) (runs: 7, μ: 8940, ~: 8940)
[PASS] test_Success_BothSlots_int256(uint128,uint128) (runs: 7, μ: 8948, ~: 8948)
[PASS] test_Success_BothSlots_uint256(uint128,uint128) (runs: 7, μ: 8898, ~: 8898)
[PASS] test_Success_DivInts(int128,int128,int128,int128) (runs: 7, μ: 18810, ~: 18672)
[PASS] test_Success_DivUints(uint128,uint128,uint128,uint128) (runs: 7, μ: 16437, ~: 16437)
[PASS] test_Success_LeftSlot_Int128_In_Int256(int128) (runs: 7, μ: 7841, ~: 7841)
[PASS] test_Success_LeftSlot_Uint128_In_Int256(uint128) (runs: 7, μ: 7859, ~: 7859)
[PASS] test_Success_LeftSlot_Uint128_In_Uint256(uint128) (runs: 7, μ: 7811, ~: 7811)
[PASS] test_Success_MulInts(int128,int128,int128,int128) (runs: 7, μ: 17063, ~: 17119)
[PASS] test_Success_MulUints(uint128,uint128,uint128,uint128) (runs: 7, μ: 16672, ~: 16395)
[PASS] test_Success_RightSlot_Int128_In_Int256(int128) (runs: 7, μ: 7869, ~: 7869)
[PASS] test_Success_RightSlot_Uint128_In_Int256(uint128) (runs: 7, μ: 7933, ~: 7933)
[PASS] test_Success_RightSlot_Uint128_In_Uint256(uint128) (runs: 7, μ: 7848, ~: 7848)
[PASS] test_Success_SubInts(int128,int128,int128,int128) (runs: 7, μ: 22505, ~: 22505)
[PASS] test_Success_SubUints(uint128,uint128,uint128,uint128) (runs: 7, μ: 16476, ~: 16134)
[PASS] test_Success_ToInt128(int256) (runs: 7, μ: 7491, ~: 8640)
[PASS] test_Success_ToInt256(uint256) (runs: 7, μ: 5742, ~: 5742)
[PASS] test_Success_ToUint128(uint256) (runs: 7, μ: 7435, ~: 8596)
Suite result: ok. 23 passed; 0 failed; 0 skipped; finished in 1.60s (150.24ms CPU time)

Ran 25 tests for test/foundry/libraries/Math.t.sol:MathTest
[PASS] test_Fail_abs_Overflow() (gas: 8428)
[PASS] test_Fail_getSqrtRatioAtTick() (gas: 10956)
[PASS] test_Fail_mulDiv192() (gas: 8528)
[PASS] test_Fail_mulDiv64() (gas: 8465)
[PASS] test_Fail_mulDiv96() (gas: 8563)
[PASS] test_Fail_toInt128_Overflow(uint128) (runs: 5, μ: 8998, ~: 8998)
[PASS] test_Fail_toUint128_Overflow(uint256) (runs: 6, μ: 8847, ~: 8847)
[PASS] test_Success_abs_X_GT_0(int256) (runs: 6, μ: 8577, ~: 8577)
[PASS] test_Success_abs_X_LE_0(int256) (runs: 6, μ: 8786, ~: 8786)
[PASS] test_Success_getAmount0ForLiquidity(uint128) (runs: 7, μ: 13848, ~: 13762)
[PASS] test_Success_getAmount1ForLiquidity(uint128) (runs: 7, μ: 9706, ~: 9706)
[PASS] test_Success_getAmountsForLiquidity(uint128) (runs: 7, μ: 13990, ~: 13732)
[PASS] test_Success_getLiquidityForAmount0(uint112) (runs: 7, μ: 10248, ~: 10248)
[PASS] test_Success_getLiquidityForAmount1(uint112) (runs: 7, μ: 9965, ~: 9965)
[PASS] test_Success_getSqrtRatioAtTick(int24) (runs: 7, μ: 16387, ~: 16187)
[PASS] test_Success_max24_A_GT_B(int24,int24) (runs: 6, μ: 9101, ~: 9101)
[PASS] test_Success_max24_A_LE_B(int24,int24) (runs: 6, μ: 9117, ~: 9117)
[PASS] test_Success_min24_A_GE_B(int24,int24) (runs: 6, μ: 9062, ~: 9062)
[PASS] test_Success_min24_A_LT_B(int24,int24) (runs: 6, μ: 9023, ~: 9023)
[PASS] test_Success_mulDiv192(uint128,uint128) (runs: 7, μ: 6241, ~: 6241)
[PASS] test_Success_mulDiv64(uint96,uint96) (runs: 7, μ: 6295, ~: 6295)
[PASS] test_Success_mulDiv96(uint96,uint96) (runs: 7, μ: 6329, ~: 6329)
[PASS] test_Success_sort(int24[]) (runs: 7, μ: 4571625, ~: 5850034)
[PASS] test_Success_toInt128(uint128) (runs: 7, μ: 8775, ~: 8775)
[PASS] test_Success_toUint128(uint256) (runs: 6, μ: 8658, ~: 8658)
Suite result: ok. 25 passed; 0 failed; 0 skipped; finished in 1.68s (227.89ms CPU time)

Ran 34 tests for test/foundry/libraries/SafeTransferLib.t.sol:SafeTransferLibTest
[PASS] testFailFuzzTransferFromWithGarbage(address,address,uint256,bytes,bytes) (runs: 7, μ: 117327, ~: 117298)
[PASS] testFailFuzzTransferFromWithReturnsFalse(address,address,uint256,bytes) (runs: 7, μ: 14514, ~: 14516)
[PASS] testFailFuzzTransferFromWithReturnsTooLittle(address,address,uint256,bytes) (runs: 7, μ: 14413, ~: 14411)
[PASS] testFailFuzzTransferFromWithReturnsTwo(address,address,uint256,bytes) (runs: 7, μ: 14527, ~: 14527)
[PASS] testFailFuzzTransferFromWithReverting(address,address,uint256,bytes) (runs: 7, μ: 10684, ~: 10681)
[PASS] testFailFuzzTransferWithGarbage(address,uint256,bytes,bytes) (runs: 7, μ: 99907, ~: 106281)
[PASS] testFailFuzzTransferWithReturnsFalse(address,uint256,bytes) (runs: 7, μ: 9325, ~: 9327)
[PASS] testFailFuzzTransferWithReturnsTooLittle(address,uint256,bytes) (runs: 7, μ: 9243, ~: 9240)
[PASS] testFailFuzzTransferWithReturnsTwo(address,uint256,bytes) (runs: 7, μ: 9364, ~: 9356)
[PASS] testFailFuzzTransferWithReverting(address,uint256,bytes) (runs: 7, μ: 9269, ~: 9271)
[PASS] testFailTransferFromWithReturnsFalse() (gas: 13561)
[PASS] testFailTransferFromWithReturnsTooLittle() (gas: 13465)
[PASS] testFailTransferFromWithReverting() (gas: 9757)
[PASS] testFailTransferWithReturnsFalse() (gas: 8472)
[PASS] testFailTransferWithReturnsTooLittle() (gas: 8457)
[PASS] testFailTransferWithReverting() (gas: 8412)
[PASS] testFuzzTransferFromWithGarbage(address,address,uint256,bytes,bytes) (runs: 7, μ: 2970, ~: 2287)
[PASS] testFuzzTransferFromWithMissingReturn(address,address,uint256,bytes) (runs: 7, μ: 49590, ~: 49552)
[PASS] testFuzzTransferFromWithNonContract(address,address,address,uint256,bytes) (runs: 7, μ: 4210, ~: 4205)
[PASS] testFuzzTransferFromWithReturnsTooMuch(address,address,uint256,bytes) (runs: 7, μ: 50272, ~: 50258)
[PASS] testFuzzTransferFromWithStandardERC20(address,address,uint256,bytes) (runs: 7, μ: 48035, ~: 48041)
[PASS] testFuzzTransferWithGarbage(address,uint256,bytes,bytes) (runs: 7, μ: 2821, ~: 2220)
[PASS] testFuzzTransferWithMissingReturn(address,uint256,bytes) (runs: 7, μ: 37567, ~: 37562)
[PASS] testFuzzTransferWithNonContract(address,address,uint256,bytes) (runs: 7, μ: 4162, ~: 4158)
[PASS] testFuzzTransferWithReturnsTooMuch(address,uint256,bytes) (runs: 7, μ: 37930, ~: 37930)
[PASS] testFuzzTransferWithStandardERC20(address,uint256,bytes) (runs: 7, μ: 37625, ~: 37624)
[PASS] testTransferFromWithMissingReturn() (gas: 49192)
[PASS] testTransferFromWithNonContract() (gas: 3014)
[PASS] testTransferFromWithReturnsTooMuch() (gas: 49852)
[PASS] testTransferFromWithStandardERC20() (gas: 47646)
[PASS] testTransferWithMissingReturn() (gas: 36704)
[PASS] testTransferWithNonContract() (gas: 2990)
[PASS] testTransferWithReturnsTooMuch() (gas: 37106)
[PASS] testTransferWithStandardERC20() (gas: 36713)
Suite result: ok. 34 passed; 0 failed; 0 skipped; finished in 11.78s (7.35s CPU time)

Ran 7 tests for test/foundry/types/TickStateCallContext.t.sol:TickStateCallContextTest
[PASS] test_Success_addCaller(uint256,address) (runs: 7, μ: 5850, ~: 5850)
[PASS] test_Success_addCurrentTick(uint256,int24) (runs: 7, μ: 5810, ~: 5810)
[PASS] test_Success_addMedianTick(uint256,int24) (runs: 7, μ: 5906, ~: 5906)
[PASS] test_Success_caller(uint256) (runs: 7, μ: 5714, ~: 5714)
[PASS] test_Success_currentTick(uint256) (runs: 7, μ: 5718, ~: 5718)
[PASS] test_Success_medianTick(uint256) (runs: 7, μ: 5768, ~: 5768)
[PASS] test_Success_updateCurrentTick(uint256,int24) (runs: 7, μ: 5832, ~: 5832)
Suite result: ok. 7 passed; 0 failed; 0 skipped; finished in 3.09ms (2.81ms CPU time)

Ran 50 tests for test/foundry/types/TokenId.t.sol:TokenIdTest
[PASS] test_Fail_asTicks_TicksNotInitializable(uint16,int24,int24) (runs: 7, μ: 30213, ~: 30063)
[PASS] test_Fail_asTicks_aboveMinTick(uint16,int24,int24) (runs: 5, μ: 29820, ~: 29708)
[PASS] test_Fail_asTicks_belowMinTick(uint16,int24,int24) (runs: 5, μ: 30559, ~: 31084)
[PASS] test_Fail_constructRollTokenIdWith(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 98329, ~: 97507)
[PASS] test_Fail_ensureIsOTM_optionsNotOTM(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 108020, ~: 107665)
[PASS] test_Fail_validateIsExercisable_inRange(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 124515, ~: 124618)
[PASS] test_Fail_validateIsExercisable_shortPos(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 93839, ~: 94391)
[PASS] test_Fail_validate_emptyLegIndexZero(uint256,uint256,uint256,uint256,uint256,int24,int256) (runs: 7, μ: 21611, ~: 21935)
[PASS] test_Fail_validate_invalidPartnerAsset(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 61968, ~: 62343)
[PASS] test_Fail_validate_invalidPartnerRatio(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 64140, ~: 64349)
[PASS] test_Fail_validate_invalidRiskPartner(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 59399, ~: 59287)
[PASS] test_Fail_validate_invalidStrikeMax(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 40381, ~: 40576)
[PASS] test_Fail_validate_invalidStrikeMin(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 40480, ~: 40464)
[PASS] test_Fail_validate_invalidWidth(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 38950, ~: 39124)
[PASS] test_Fail_validate_legsWithGaps(uint256,uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 95876, ~: 95840)
[PASS] test_Fail_validate_riskRegularPos(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 70431, ~: 70526)
[PASS] test_Fail_validate_synthPos(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 68414, ~: 68283)
[PASS] test_Success_AddAsset(uint16,uint16,uint16,uint16) (runs: 7, μ: 25852, ~: 25852)
[PASS] test_Success_AddIsLong(uint16,uint16,uint16,uint16) (runs: 7, μ: 37117, ~: 37117)
[PASS] test_Success_AddLeg(uint256,uint16,uint16,uint16,uint16,uint16,int24,int24) (runs: 7, μ: 30200, ~: 30060)
[PASS] test_Success_AddOptionRatio(uint16,uint16,uint16,uint16) (runs: 7, μ: 25546, ~: 25546)
[PASS] test_Success_AddRiskPartner(uint16,uint16,uint16,uint16) (runs: 7, μ: 26368, ~: 26368)
[PASS] test_Success_AddStrike(int24,int24,int24,int24) (runs: 7, μ: 26872, ~: 26872)
[PASS] test_Success_AddTokenType(uint16,uint16,uint16,uint16) (runs: 7, μ: 25631, ~: 25631)
[PASS] test_Success_AddUniv3Pool(address) (runs: 7, μ: 6912, ~: 6912)
[PASS] test_Success_AddWidth(int24,int24,int24,int24) (runs: 7, μ: 27167, ~: 27161)
[PASS] test_Success_asTicks_normalTickRange(uint16,int24,int24) (runs: 5, μ: 31122, ~: 31177)
[PASS] test_Success_clearLeg_Four(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 91659, ~: 90965)
[PASS] test_Success_clearLeg_Null(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 91187, ~: 90907)
[PASS] test_Success_clearLeg_One(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 91713, ~: 91356)
[PASS] test_Success_clearLeg_Three(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 91674, ~: 91817)
[PASS] test_Success_clearLeg_Two(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 91005, ~: 90676)
[PASS] test_Success_constructRollTokenIdWith(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 46167, ~: 46261)
[PASS] test_Success_countLegs_emptyLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 19577, ~: 19902)
[PASS] test_Success_countLegs_fourLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 89931, ~: 89572)
[PASS] test_Success_countLegs_oneLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 38154, ~: 38189)
[PASS] test_Success_countLegs_threeLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 73672, ~: 73368)
[PASS] test_Success_countLegs_twoLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 55665, ~: 55795)
[PASS] test_Success_countLongs(uint256,uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 67674, ~: 62797)
[PASS] test_Success_ensureIsOTM(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 108344, ~: 108457)
[PASS] test_Success_flipToBurnToken_OneLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 40701, ~: 40796)
[PASS] test_Success_flipToBurnToken_emptyLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 8881, ~: 8881)
[PASS] test_Success_flipToBurnToken_fourLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 93275, ~: 93070)
[PASS] test_Success_flipToBurnToken_threeLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 76170, ~: 76049)
[PASS] test_Success_flipToBurnToken_twoLegs(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 58205, ~: 57855)
[PASS] test_Success_rollTokenInfo(uint256,uint256,uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 182891, ~: 184306)
[PASS] test_Success_rolledTokenIsValid(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 42714, ~: 42609)
[PASS] test_Success_validate(uint256,uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 68266, ~: 60293)
[PASS] test_Success_validateIsExercisable_aboveTick(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 126655, ~: 126832)
[PASS] test_Success_validateIsExercisable_belowTick(uint64,uint256,uint256,uint256,uint256,int24,int256,int24) (runs: 7, μ: 128025, ~: 127788)
Suite result: ok. 50 passed; 0 failed; 0 skipped; finished in 110.85ms (110.05ms CPU time)

Ran 3 tests for test/foundry/libraries/FeesCalc.t.sol:FeesCalcTest
[PASS] test_Success_calculateAMMSwapFees(int24,uint256,uint256,uint256,uint256,uint256,uint256,int256,int256,uint64) (runs: 7, μ: 127370, ~: 124896)
[PASS] test_Success_calculateAMMSwapFeesLiquidityChunk(int24,uint256,uint256,uint256,uint256,uint256,uint256,int256,int256,uint64,uint64) (runs: 7, μ: 120283, ~: 119271)
[PASS] test_Success_getPortfolioValue(int24,uint256,uint256,uint256,uint256,uint256,uint256,int256,int256,uint64) (runs: 7, μ: 128057, ~: 127419)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 27.07s (31.16s CPU time)

Ran 3 tests for test/foundry/libraries/CallbackLib.t.sol:CallbackLibTest
[PASS] test_Fail_validateCallback(address,address,address,uint24) (runs: 7, μ: 10790, ~: 10787)
[PASS] test_Fail_validateCallback_Targeted(address,address,address,uint24) (runs: 7, μ: 4553576, ~: 4553753)
[PASS] test_Success_validateCallback(address,address,uint256) (runs: 7, μ: 4552923, ~: 4552941)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 30.27s (16.84s CPU time)

Ran 15 tests for test/foundry/tokens/ERC1155Minimal.t.sol:ERC1155Minimal
[PASS] testFail_safeBatchTransferFrom_insufficientBalance(address,uint256[10],uint256[10],uint256[10],uint256) (runs: 7, μ: 8776, ~: 8776)
[PASS] testFail_safeTransferFrom_insufficientBalance(address,uint256,uint256,uint256) (runs: 7, μ: 43493, ~: 43458)
[PASS] testFail_safeTransferFrom_unapproved(address,uint256,uint256) (runs: 7, μ: 40713, ~: 40713)
[PASS] testFail_safeTransferFrom_unapproved(address,uint256[10],uint256[10]) (runs: 7, μ: 276859, ~: 282831)
[PASS] testFail_safeTransferFrom_unsafeRecipient(uint256,uint256) (runs: 7, μ: 37318, ~: 37318)
[PASS] testFail_safeTransferFrom_unsafeRecipient(uint256[10],uint256[10]) (runs: 7, μ: 279478, ~: 279478)
[PASS] testSuccess_balanceOfBatch(address[10],uint256[10],uint256[10]) (runs: 7, μ: 552109, ~: 552824)
[PASS] testSuccess_safeBatchTransferFrom(address,uint256[10],uint256[10]) (runs: 6, μ: 604365, ~: 609555)
[PASS] testSuccess_safeBatchTransferFrom_approved(address,uint256[10],uint256[10]) (runs: 6, μ: 619887, ~: 630259)
[PASS] testSuccess_safeTransferFrom(address,uint256,uint256) (runs: 7, μ: 46588, ~: 46594)
[PASS] testSuccess_safeTransferFrom_approved(address,uint256,uint256) (runs: 7, μ: 69814, ~: 69814)
[PASS] testSuccess_setApprovalForAll(address,uint256,uint256) (runs: 7, μ: 56807, ~: 56807)
[PASS] testSuccess_supportsInterface_ERC1155() (gas: 5729)
[PASS] testSuccess_supportsInterface_ERC165() (gas: 5669)
[PASS] testSuccess_supportsInterface_unsupported(bytes4) (runs: 7, μ: 8971, ~: 8971)
Suite result: ok. 15 passed; 0 failed; 0 skipped; finished in 39.44s (37.87s CPU time)

Ran 41 tests for test/foundry/libraries/PanopticMath.t.sol:PanopticMathTest
[PASS] test_Fail_convert0to1_PriceX128_Int_CastingError(int256,uint256) (runs: 5, μ: 15625, ~: 15763)
[PASS] test_Fail_convert0to1_PriceX128_Int_overflow(int256,uint256) (runs: 6, μ: 14660, ~: 14764)
[PASS] test_Fail_convert0to1_PriceX128_Uint_overflow(uint256,uint256) (runs: 6, μ: 14379, ~: 14626)
[PASS] test_Fail_convert0to1_PriceX192_Int_CastingError(int256,uint256) (runs: 5, μ: 15335, ~: 15542)
[PASS] test_Fail_convert0to1_PriceX192_Int_overflow(int256,uint256) (runs: 5, μ: 14487, ~: 14636)
[PASS] test_Fail_convert0to1_PriceX192_Uint_overflow(uint256,uint256) (runs: 5, μ: 14497, ~: 14497)
[PASS] test_Fail_convert1to0_PriceX192_Int_CastingError(int256,uint256) (runs: 5, μ: 15359, ~: 15311)
[PASS] test_Fail_convert1to0_PriceX192_Int_overflow(int256,uint256) (runs: 5, μ: 13989, ~: 14006)
[PASS] test_Fail_convert1to0_PriceX192_Uint_overflow(uint256,uint256) (runs: 6, μ: 13875, ~: 13829)
[PASS] test_Success_calculateIOAmounts_longTokenType0(uint16,uint16,int24,int24,uint64) (runs: 5, μ: 100067, ~: 100039)
[PASS] test_Success_calculateIOAmounts_longTokenType1(uint16,uint16,int24,int24,uint64) (runs: 5, μ: 92595, ~: 92479)
[PASS] test_Success_calculateIOAmounts_shortTokenType0(uint16,uint16,int24,int24,uint64) (runs: 5, μ: 94855, ~: 94881)
[PASS] test_Success_calculateIOAmounts_shortTokenType1(uint16,uint16,int24,int24,uint64) (runs: 5, μ: 92035, ~: 92463)
[PASS] test_Success_computeExercisedAmounts_emptyOldTokenId(uint16,uint16,uint16,uint16,int24,int24,uint64) (runs: 6, μ: 96150, ~: 96170)
[PASS] test_Success_computeExercisedAmounts_fullOldTokenId(uint16,uint16,uint16,uint16,int24,int24,int24,uint64) (runs: 7, μ: 111627, ~: 111466)
[PASS] test_Success_convert0to1_PriceX128_Int(int256,uint256) (runs: 6, μ: 16045, ~: 16267)
[PASS] test_Success_convert0to1_PriceX128_Uint(uint256,uint256) (runs: 6, μ: 14873, ~: 15050)
[PASS] test_Success_convert0to1_PriceX192_Int(int256,uint256) (runs: 7, μ: 15584, ~: 15441)
[PASS] test_Success_convert0to1_PriceX192_Uint(uint256,uint256) (runs: 7, μ: 14668, ~: 14881)
[PASS] test_Success_convert1to0_PriceX128_Int(int256,uint256) (runs: 7, μ: 16037, ~: 15686)
[PASS] test_Success_convert1to0_PriceX128_Uint(uint256,uint256) (runs: 7, μ: 14795, ~: 14709)
[PASS] test_Success_convert1to0_PriceX192_Int(int256,uint256) (runs: 7, μ: 15652, ~: 15609)
[PASS] test_Success_convert1to0_PriceX192_Uint(uint256,uint256) (runs: 6, μ: 14542, ~: 14571)
[PASS] test_Success_convertCollateralData_Tick_tokenType0(int256,uint128,uint128,uint128,uint128) (runs: 7, μ: 18575, ~: 18528)
[PASS] test_Success_convertCollateralData_Tick_tokenType1(int256,uint128,uint128,uint128,uint128) (runs: 7, μ: 18294, ~: 18455)
[PASS] test_Success_convertCollateralData_sqrtPrice_tokenType0(uint256,uint128,uint128,uint128,uint128) (runs: 7, μ: 13505, ~: 13797)
[PASS] test_Success_convertCollateralData_sqrtPrice_tokenType1(uint256,uint128,uint128,uint128,uint128) (runs: 7, μ: 13925, ~: 13925)
[PASS] test_Success_convertNotional_asset0(int256,int256,uint128) (runs: 7, μ: 24442, ~: 24678)
[PASS] test_Success_convertNotional_asset0_InvalidNotionalValue(int256,int256,uint128) (runs: 5, μ: 24259, ~: 24146)
[PASS] test_Success_convertNotional_asset1(int256,int256,uint128) (runs: 5, μ: 24703, ~: 24739)
[PASS] test_Success_convertNotional_asset1_InvalidNotionalValue(int256,int256,uint128) (runs: 5, μ: 24575, ~: 24410)
[PASS] test_Success_getAmountsMoved_asset0(uint16,uint16,uint16,uint16,int24,int24,uint64) (runs: 7, μ: 90612, ~: 90722)
[PASS] test_Success_getAmountsMoved_asset1(uint16,uint16,uint16,uint16,int24,int24,uint64) (runs: 6, μ: 94522, ~: 94718)
[PASS] test_Success_getFinalPoolId(uint64,address,address,uint8) (runs: 7, μ: 11607, ~: 11805)
[PASS] test_Success_getLiquidityChunk_asset0(uint16,uint16,uint16,int24,int24,uint64) (runs: 7, μ: 93730, ~: 93948)
[PASS] test_Success_getLiquidityChunk_asset1(uint16,uint16,uint16,int24,int24,uint64) (runs: 7, μ: 92854, ~: 92957)
[PASS] test_Success_getPoolId(address) (runs: 7, μ: 6025, ~: 6025)
[PASS] test_Success_numberOfLeadingHexZeros(address) (runs: 7, μ: 10003, ~: 10031)
[PASS] test_Success_twapFilter(uint32) (runs: 7, μ: 678670, ~: 774768)
[PASS] test_Success_updatePositionsHash_add(uint16,uint16,uint16,uint16,int24,int24,uint256) (runs: 7, μ: 86316, ~: 86553)
[PASS] test_Success_updatePositionsHash_update(uint16,uint16,uint16,uint16,int24,int24,uint256) (runs: 7, μ: 85946, ~: 85952)
Suite result: ok. 41 passed; 0 failed; 0 skipped; finished in 51.11s (49.66s CPU time)

Ran 9 tests for test/foundry/core/PanopticFactory.t.sol:PanopticFactoryTest
[PASS] test_Fail_deployExistingPool() (gas: 1552608)
[PASS] test_Fail_deployNewPool_UnsupportedPool() (gas: 547880)
[PASS] test_Fail_deployinvalidPool() (gas: 23821)
[PASS] test_Fail_unauthorizedOwner(address) (runs: 7, μ: 17784, ~: 17784)
[PASS] test_Success_deployNewPool(uint256,uint96) (runs: 7, μ: 2418096, ~: 1727341)
[PASS] test_Success_deployNewPoolToken1() (gas: 3864667)
[PASS] test_Success_deployNewPoolWETH0() (gas: 1535008)
[PASS] test_Success_mineTargetRarity(uint256,uint96,uint256) (runs: 7, μ: 1679894, ~: 1585380)
[PASS] test_Success_setOwner(address) (runs: 7, μ: 18714, ~: 18714)
Suite result: ok. 9 passed; 0 failed; 0 skipped; finished in 98.59s (98.50s CPU time)



Ran 6 tests for test/foundry/periphery/PanopticHelper.t.sol:PanopticHelperTest
[PASS] test_Success_checkCollateral_OTMandITMShortCall(uint256,uint256[2],int256[2],uint256[2],int256,bool,uint256) (runs: 7, μ: 12605697, ~: 14050966)
[PASS] test_Success_wrapUnwrapTokenIds_1Leg(uint256,int24,int24,bool,uint8,bool,bool) (runs: 502, μ: 7574950, ~: 7574961)
[PASS] test_Success_wrapUnwrapTokenIds_2LegsSpread(uint256,int24,int24,int24,bool,uint8,bool) (runs: 7, μ: 7588634, ~: 7588717)
[PASS] test_Success_wrapUnwrapTokenIds_multiLegsNoPartners(uint256,uint256) (runs: 102, μ: 7585371, ~: 7585365)
[PASS] test_Success_wrapUnwrapTokenIds_multiLegsWithPartners_Spreads(uint256,uint256) (runs: 102, μ: 7608378, ~: 7607626)
[PASS] test_Success_wrapUnwrapTokenIds_multiLegsWithPartners_Strangles(uint256,uint256) (runs: 102, μ: 7608795, ~: 7607735)
Suite result: ok. 6 passed; 0 failed; 0 skipped; finished in 268.42s (273.01s CPU time)

Ran 35 tests for test/foundry/core/SemiFungiblePositionManager.t.sol:SemiFungiblePositionManagerTest
[PASS] testSuccess_afterTokenTransfer_Batch(uint256,uint256,int256,uint256) (runs: 7, μ: 1986464, ~: 1983573)
[PASS] testSuccess_afterTokenTransfer_Single(uint256,uint256,int256,uint256) (runs: 7, μ: 1829493, ~: 1817472)
[PASS] test_Fail_afterTokenTransfer_NotAllLiquidityTransferred(uint256,uint256,int256,uint256,uint256) (runs: 7, μ: 1806218, ~: 1814316)
[PASS] test_Fail_afterTokenTransfer_RecipientAlreadyOwns(uint256,uint256,int256,uint256[2],uint256) (runs: 7, μ: 1891061, ~: 1892925)
[PASS] test_Fail_burnTokenizedPosition_ReentrancyLock(uint256,uint256,int256,uint256,uint256) (runs: 7, μ: 2230184, ~: 2241959)
[PASS] test_Fail_initializeAMMPool_uniswapPoolNotInitialized() (gas: 18528)
[PASS] test_Fail_mintTokenizedPosition_OutsideRangeShortCallLongCallCombinedInsufficientLiq(uint256,uint256,int256,uint256,uint256,uint256) (runs: 7, μ: 1793516, ~: 1794996)
[PASS] test_Fail_mintTokenizedPosition_PoolNotInitialized(uint256,uint256,int256,uint256) (runs: 7, μ: 1525973, ~: 1525912)
[PASS] test_Fail_mintTokenizedPosition_PriceBoundFail(uint256,uint256,int256,uint256,int256,int256) (runs: 7, μ: 1779823, ~: 1793112)
[PASS] test_Fail_mintTokenizedPosition_ReentrancyLock(uint256,uint256,int256,uint256) (runs: 7, μ: 2026668, ~: 2026570)
[PASS] test_Fail_mintTokenizedPosition_positionSize0(uint256,uint256,int256) (runs: 7, μ: 1342440, ~: 1342534)
[PASS] test_Fail_rollTokenizedPosition_ReentrancyLock(uint256,uint256,uint256,int256,int256,uint256) (runs: 7, μ: 2730382, ~: 2723214)
[PASS] test_Fail_uniswapV3MintCallback_Unauthorized(uint256) (runs: 7, μ: 1285465, ~: 1285496)
[PASS] test_Fail_uniswapV3SwapCallback_Unauthorized(uint256) (runs: 7, μ: 1285489, ~: 1285513)
[PASS] test_Sanity_ITMSwapApprox(uint256,int256,int256) (runs: 7, μ: 19454, ~: 19387)
[PASS] test_Success_burnTokenizedPosition_InRangeShortPutSwap(uint256,uint256,int256,uint256,uint256) (runs: 7, μ: 3578313, ~: 3597766)
[PASS] test_Success_burnTokenizedPosition_OutsideRangeShortCall(uint256,uint256,int256,uint256,uint256) (runs: 7, μ: 1809317, ~: 1784966)
[PASS] test_Success_burnTokenizedPosition_OutsideRangeShortCallLongCallCombined(uint256,uint256,int256,uint256,uint256,uint256,uint256) (runs: 7, μ: 1938813, ~: 1930563)
[PASS] test_Success_getAccountPremium_getAccountFeesBase_ShortOnly(uint256,uint256,int256,uint256,uint256) (runs: 7, μ: 2014709, ~: 1998500)
[PASS] test_Success_initializeAMMPool_HandleCollisions() (gas: 10284964)
[PASS] test_Success_initializeAMMPool_Multiple() (gas: 324269)
[PASS] test_Success_initializeAMMPool_Single(uint256) (runs: 7, μ: 1327368, ~: 1327400)
[PASS] test_Success_mintTokenizedPosition_ITMShortPutLongCallCombinedSwap(uint256,uint256[2],int256[2],uint256[2]) (runs: 7, μ: 3970675, ~: 3888791)
[PASS] test_Success_mintTokenizedPosition_ITMShortPutShortCallCombinedSwap(uint256,uint256[2],int256[2],uint256) (runs: 5, μ: 3725579, ~: 3630172)
[PASS] test_Success_mintTokenizedPosition_InRangeShortCallSwap(uint256,uint256,int256,uint256) (runs: 7, μ: 3533806, ~: 3448586)
[PASS] test_Success_mintTokenizedPosition_InRangeShortPutNoSwap(uint256,uint256,int256,uint256) (runs: 7, μ: 1775242, ~: 1765503)
[PASS] test_Success_mintTokenizedPosition_InRangeShortPutSwap(uint256,uint256,int256,uint256) (runs: 7, μ: 3153145, ~: 3218254)
[PASS] test_Success_mintTokenizedPosition_OutOfRangeShortCallLongCallCombined(uint256,uint256,int256,uint256,uint256,uint256) (runs: 7, μ: 1852111, ~: 1845040)
[PASS] test_Success_mintTokenizedPosition_OutsideRangeShortCall(uint256,uint256,int256,uint256) (runs: 7, μ: 1769802, ~: 1794685)
[PASS] test_Success_mintTokenizedPosition_OutsideRangeShortPut(uint256,uint256,int256,uint256) (runs: 7, μ: 1763060, ~: 1748100)
[PASS] test_Success_mintTokenizedPosition_PriceBound(uint256,uint256,int256,uint256,int256,int256) (runs: 7, μ: 1792148, ~: 1806639)
[PASS] test_Success_mintTokenizedPosition_minorPosition(uint256,uint256,int256,uint256) (runs: 7, μ: 981665, ~: 997635)
[PASS] test_Success_premiaSpreadMechanism(uint256,uint256,int256,uint256,uint256,uint256) (runs: 7, μ: 5917214, ~: 5202981)
[PASS] test_Success_rollTokenizedPosition_2xOutsideRangeShortCall(uint256,uint256,uint256,int256,int256,uint256) (runs: 7, μ: 2285138, ~: 2262546)
[PASS] test_Success_rollTokenizedPosition_OutsideRangeShortCallPoolChange(uint256,uint256,uint256,int256,uint256) (runs: 6, μ: 2822724, ~: 2835590)
Suite result: ok. 35 passed; 0 failed; 0 skipped; finished in 395.58s (646.83s CPU time)

Ran 62 tests for test/foundry/core/CollateralTracker.t.sol:CollateralTrackerTest
[PASS] test_Fail_computeBonus_OptionsBalanceZero(uint256,int128,uint128,int256,uint256) (runs: 6, μ: 56894170, ~: 56895553)
[PASS] test_Fail_computeBonus_notMarginCalled(uint256,int128,uint128,int256,uint256) (runs: 6, μ: 56894023, ~: 56886454)
[PASS] test_Fail_computeBonus_posPremiumHealthyAcc(uint256,int128,uint128,int256,uint256,int128,int128) (runs: 5, μ: 56890630, ~: 56850051)
[PASS] test_Fail_deposit_DepositTooLarge(uint256,uint256) (runs: 7, μ: 55054490, ~: 55041339)
[PASS] test_Fail_mint_DepositTooLarge(uint256,uint256) (runs: 7, μ: 55285993, ~: 55264489)
[PASS] test_Fail_redeem_exceedsMax(uint256,uint256) (runs: 7, μ: 55652584, ~: 55618444)
[PASS] test_Fail_redeem_onBehalf(uint128) (runs: 7, μ: 55643771, ~: 55620676)
[PASS] test_Fail_startToken_alreadyInitializedToken(uint256) (runs: 7, μ: 68803121, ~: 68799732)
[PASS] test_Fail_transferFrom_positionCountNotZero(uint256,uint256,int256,uint128) (runs: 7, μ: 56643673, ~: 56627013)
[PASS] test_Fail_transfer_positionCountNotZero(uint256,uint104,uint256,int256,uint128) (runs: 7, μ: 62139535, ~: 56713483)
[PASS] test_Fail_withdraw_ExceedsMax(uint256) (runs: 7, μ: 55622170, ~: 55599579)
[PASS] test_Fail_withdraw_onBehalf(uint256) (runs: 7, μ: 55640085, ~: 55605946)
[PASS] test_Success_Redeem_onBehalf(uint128,uint104) (runs: 7, μ: 55716442, ~: 55703540)
[PASS] test_Success_availableAssets(uint256,uint256) (runs: 7, μ: 54840841, ~: 54838411)
[PASS] test_Success_collateralCheck_ITMcallSpread_assetTT0(uint256,uint128,uint256,uint256,int256,int256,int24,uint256) (runs: 5, μ: 122015281, ~: 126890258)
[PASS] test_Success_collateralCheck_ITMcallSpread_assetTT1(uint256,uint128,uint256,uint256,int256,int256,int24,uint256) (runs: 6, μ: 128153607, ~: 127279729)
[PASS] test_Success_collateralCheck_ITMputSpread(uint256,uint128,uint256,uint256,int256,int256,int24,uint256) (runs: 7, μ: 118250707, ~: 119150122)
[PASS] test_Success_collateralCheck_OTMCallIdenticalSpread(uint256,uint128,uint256,int256,int24) (runs: 7, μ: 112490353, ~: 112476720)
[PASS] test_Success_collateralCheck_OTMPutIdenticalSpread(uint256,uint128,uint256,int256,int24) (runs: 6, μ: 112721235, ~: 112704305)
[PASS] test_Success_collateralCheck_OTMcallSpread(uint256,uint128,uint256,uint256,int256,int256,int24,uint256) (runs: 6, μ: 118833446, ~: 116517598)
[PASS] test_Success_collateralCheck_OTMputSpread(uint256,uint128,uint256,uint256,int256,int256,int24,uint24) (runs: 6, μ: 117855232, ~: 116579768)
[PASS] test_Success_collateralCheck_buyBetweenTargetSaturated(uint256,uint128,uint256,int256,uint256,int256,uint64,int24,uint256) (runs: 7, μ: 117588347, ~: 114777849)
[PASS] test_Success_collateralCheck_buyCallMinUtilization(uint256,uint128,uint256,int256,uint256,int256,uint64,int24,uint256) (runs: 7, μ: 118892730, ~: 115299068)
[PASS] test_Success_collateralCheck_buyGTSaturatedPoolUtilization(uint256,uint128,uint256,int256,uint256,int256,uint64,int24,uint256) (runs: 7, μ: 121193824, ~: 125738174)
[PASS] test_Success_collateralCheck_longStrangle(uint256,uint128,uint256,int256,uint256,int256,int24,uint64) (runs: 6, μ: 112499489, ~: 112503023)
[PASS] test_Success_collateralCheck_sellCallBetweenTargetSaturated_asset1(uint256,uint128,uint256,int256,uint256,int256,uint64,int24,uint256) (runs: 7, μ: 117131440, ~: 115398000)
[PASS] test_Success_collateralCheck_sellCallGTSaturatedPoolUtilization_TT0(uint256,uint128,uint256,int256,uint256,int256,uint64,int24,uint256) (runs: 7, μ: 118227524, ~: 114492167)
[PASS] test_Success_collateralCheck_sellCallMinUtilization(uint256,uint128,uint256,int256,uint64,int24,uint256) (runs: 7, μ: 116371955, ~: 112774430)
[PASS] test_Success_collateralCheck_sellPosPremia(uint256,uint128,uint256,int256,uint64,int24,uint24) (runs: 7, μ: 118861404, ~: 124555072)
[PASS] test_Success_collateralCheck_sellPutBetweenTargetSaturated_asset0(uint256,uint128,uint256,int256,uint256,int256,uint64,int24,uint256) (runs: 6, μ: 112987587, ~: 112207317)
[PASS] test_Success_collateralCheck_sellPutGTSaturatedPoolUtilization(uint256,uint128,uint256,int256,uint256,int256,uint64,int24,uint256) (runs: 6, μ: 120090566, ~: 121564261)
[PASS] test_Success_collateralCheck_sellPutMinUtilization(uint256,uint128,uint256,int256,uint64,int24,uint256) (runs: 7, μ: 122210509, ~: 125396778)
[PASS] test_Success_collateralCheck_shortStrangle(uint256,uint128,uint256,int256,uint256,int256,int24,uint128) (runs: 7, μ: 113191998, ~: 113207032)
[PASS] test_Success_computeBonus(uint256,uint128,int256,uint256,uint256) (runs: 7, μ: 57102952, ~: 57029807)
[PASS] test_Success_computeBonus_invalidPrice(uint256,uint128,int256,uint256) (runs: 7, μ: 57873173, ~: 57839166)
[PASS] test_Success_convertToAssets_supplyNonZero(uint256,uint104) (runs: 7, μ: 55224210, ~: 55210498)
[PASS] test_Success_convertToAssets_supplyZero(uint256,uint256) (runs: 7, μ: 54799293, ~: 54802688)
[PASS] test_Success_convertToShares_supplyNonZero(uint256,uint104) (runs: 7, μ: 55231552, ~: 55210859)
[PASS] test_Success_convertToShares_supplyZero(uint256,uint128) (runs: 7, μ: 54798360, ~: 54794977)
[PASS] test_Success_decimals(uint256) (runs: 7, μ: 54796283, ~: 54793142)
[PASS] test_Success_delegate(uint256,uint104) (runs: 7, μ: 55232753, ~: 55226378)
[PASS] test_Success_deposit(uint256,uint104) (runs: 7, μ: 55233970, ~: 55212868)
[PASS] test_Success_maxDeposit(uint256) (runs: 7, μ: 54794282, ~: 54797695)
[PASS] test_Success_maxMint(uint256) (runs: 7, μ: 54795570, ~: 54793321)
[PASS] test_Success_maxRedeem(uint256,uint104) (runs: 7, μ: 55250637, ~: 55271577)
[PASS] test_Success_maxWithdraw(uint256,uint104) (runs: 7, μ: 55242366, ~: 55228039)
[PASS] test_Success_mint(uint256,uint104) (runs: 7, μ: 55267575, ~: 55253767)
[PASS] test_Success_name(uint256) (runs: 7, μ: 54811425, ~: 54813865)
[PASS] test_Success_poolData(uint256) (runs: 7, μ: 54815278, ~: 54814162)
[PASS] test_Success_previewDeposit(uint256) (runs: 7, μ: 55232901, ~: 55212560)
[PASS] test_Success_previewMint(uint256,uint104) (runs: 7, μ: 55232853, ~: 55212514)
[PASS] test_Success_previewRedeem(uint256) (runs: 7, μ: 55225327, ~: 55211866)
[PASS] test_Success_previewWithdraw(uint256) (runs: 7, μ: 55225868, ~: 55212309)
[PASS] test_Success_redeem(uint256,uint104) (runs: 7, μ: 55683996, ~: 55647429)
[PASS] test_Success_revoke(uint256,uint104) (runs: 7, μ: 55265845, ~: 55279865)
[PASS] test_Success_revoke_mint(uint256,uint128,uint256,uint256) (runs: 6, μ: 55390826, ~: 55377264)
[PASS] test_Success_symbol(uint256) (runs: 7, μ: 54799382, ~: 54798366)
[PASS] test_Success_totalAssets(uint256,uint128,uint128) (runs: 7, μ: 54843827, ~: 54842868)
[PASS] test_Success_transfer(uint256,uint104) (runs: 7, μ: 55657190, ~: 55692168)
[PASS] test_Success_transferFrom(uint256,uint104) (runs: 7, μ: 55293064, ~: 55279352)
[PASS] test_Success_withdraw(uint256,uint104) (runs: 7, μ: 55103549, ~: 55089949)
[PASS] test_Success_withdraw_OnBehalf(uint256,uint104) (runs: 7, μ: 55779360, ~: 55815979)
Suite result: ok. 62 passed; 0 failed; 0 skipped; finished in 407.36s (2014.58s CPU time)

Ran 38 tests for test/foundry/core/PanopticPool.t.sol:PanopticPoolTest
[PASS] test_Diff_4x1_1x4(uint256,uint256[4],uint256[4],uint256[4],int256[4],uint256,uint256) (runs: 7, μ: 13434711, ~: 13504285)
[PASS] test_Fail_burnOptions_OptionsBalanceZero(uint256) (runs: 7, μ: 7589103, ~: 7589084)
[PASS] test_Fail_forceExercise_1PositionNotSpecified(uint256,uint256[]) (runs: 7, μ: 7575141, ~: 7566792)
[PASS] test_Fail_forceExercise_InsufficientCollateralDecrease_NoPositions(uint256,uint256,int256,uint256) (runs: 7, μ: 9427156, ~: 9420691)
[PASS] test_Fail_forceExercise_PositionNotExercisable(uint256) (runs: 7, μ: 8284379, ~: 8284423)
[PASS] test_Fail_mintOptions_IncorrectPool(uint256,uint256,int256,uint256) (runs: 7, μ: 7962328, ~: 7962470)
[PASS] test_Fail_mintOptions_LowerPriceBoundFail(uint256,uint256,int256,uint256) (runs: 7, μ: 8210373, ~: 8208090)
[PASS] test_Fail_mintOptions_OTMShortCall_EffectiveLiquidityAboveThreshold(uint256,uint256,int256,uint256) (runs: 7, μ: 8486185, ~: 8491285)
[PASS] test_Fail_mintOptions_OTMShortCall_NotEnoughCollateral(uint256,uint256,int256,uint256) (runs: 7, μ: 8294858, ~: 8290505)
[PASS] test_Fail_mintOptions_PositionAlreadyMinted(uint256,uint256,int256,uint256) (runs: 7, μ: 8367729, ~: 8372521)
[PASS] test_Fail_mintOptions_TooManyPositionsOpen() (gas: 27741936)
[PASS] test_Fail_mintOptions_UpperPriceBoundFail(uint256,uint256,int256,uint256) (runs: 7, μ: 8211664, ~: 8207861)
[PASS] test_Fail_startPool_PoolAlreadyInitialized(uint256) (runs: 7, μ: 7555622, ~: 7555644)
[PASS] test_Fail_updateParameters_NotOwner(uint256) (runs: 7, μ: 7555619, ~: 7555679)
[PASS] test_Success_burnOptions_ITMShortCall_noPremia(uint256,uint256,int256,uint256) (runs: 7, μ: 9443694, ~: 9450476)
[PASS] test_Success_burnOptions_ITMShortCall_premia_insufficientLocked(uint256,uint256,int256,uint256,uint256,uint256) (runs: 7, μ: 11045561, ~: 11012048)
[PASS] test_Success_burnOptions_ITMShortCall_premia_sufficientLocked(uint256,uint256,int256,uint256,uint256) (runs: 7, μ: 10380614, ~: 10439118)
[PASS] test_Success_burnOptions_OTMShortCall_noPremia(uint256,uint256,int256,uint256) (runs: 7, μ: 8227186, ~: 8223016)
[PASS] test_Success_burnOptions_burnAllOptionsFrom(uint256,uint256,uint256,int256,int256,uint256,uint256) (runs: 7, μ: 8471773, ~: 8471660)
[PASS] test_Success_calculateAccumulatedFeesBatch_2xOTMShortCall(uint256,uint256[2],int256[2],uint256[2],uint256) (runs: 12, μ: 9523754, ~: 9528062)
[PASS] test_Success_calculateAccumulatedFeesBatch_VeryLargePremia(uint256,uint256,uint256[2]) (runs: 7, μ: 8095985, ~: 8096570)
[PASS] test_Success_calculatePortfolioValue_2xOTMShortCall(uint256,uint256[2],int256[2],uint256[2],uint256) (runs: 7, μ: 8682524, ~: 8693596)
[PASS] test_Success_forceExerciseDelta(uint256,uint256,uint256[4],uint256[4],uint256[4],int256[4],uint256,uint256) (runs: 7, μ: 13070995, ~: 13046215)
[PASS] test_Success_forceExerciseNoDelta(uint256,uint256,uint256[4],uint256[4],uint256[4],int256[4],uint256) (runs: 7, μ: 10308058, ~: 9987541)
[PASS] test_Success_forceExercise_BurningOpenPosition(uint256,uint256,int256,uint256) (runs: 7, μ: 9581230, ~: 9592167)
[PASS] test_Success_getPriceArray_Initialization(uint256,int256) (runs: 7, μ: 8048515, ~: 8048654)
[PASS] test_Success_getPriceArray_Poking(uint256,int256[50],uint256[50]) (runs: 7, μ: 8687911, ~: 8710506)
[PASS] test_Success_getRefundAmounts(uint256,uint256,uint256,int256,int256,int256) (runs: 7, μ: 7648840, ~: 7648566)
[PASS] test_Success_mintOptions_ITMShortCall(uint256,uint256,int256,uint256) (runs: 7, μ: 9631021, ~: 9638176)
[PASS] test_Success_mintOptions_ITMShortPutLongCall(uint256,uint256[2],int256[2],uint256[2]) (runs: 7, μ: 11104217, ~: 10972947)
[PASS] test_Success_mintOptions_ITMShortPutShortCall(uint256,uint256[2],int256[2],uint256) (runs: 7, μ: 10304826, ~: 10204555)
[PASS] test_Success_mintOptions_OTMShortCall(uint256,uint256,int256,uint256) (runs: 7, μ: 8318847, ~: 8317449)
[PASS] test_Success_mintOptions_OTMShortCall_LiquidityLimit(uint256,uint256,int256,uint256) (runs: 7, μ: 8501824, ~: 8501879)
[PASS] test_Success_mintOptions_OTMShortCall_NoLiquidityLimit(uint256,uint256,int256,uint256) (runs: 7, μ: 8501934, ~: 8501729)
[PASS] test_Success_mintOptions_OTMShortCall_SlippageSet(uint256,uint256,int256,uint256) (runs: 7, μ: 8326053, ~: 8329963)
[PASS] test_Success_mintOptions_OTMShortPut(uint256,uint256,int256,uint256) (runs: 7, μ: 8390452, ~: 8388067)
[PASS] test_Success_parameters_initialState(uint256) (runs: 7, μ: 7561321, ~: 7561365)
[PASS] test_Success_updateParameters(uint256,uint256,int256,int128[7]) (runs: 7, μ: 7592402, ~: 7592503)
Suite result: ok. 38 passed; 0 failed; 0 skipped; finished in 407.36s (731.20s CPU time)

Ran 16 test suites in 407.85s (1741.97s CPU time): 361 tests passed, 0 failed, 0 skipped (361 total tests)
```
