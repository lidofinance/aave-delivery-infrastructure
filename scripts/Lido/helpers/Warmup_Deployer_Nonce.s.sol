// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../contracts/MockDestination.sol';

import '../BaseScript.sol';

abstract contract WarmUpDeployer is BaseScript {
  function _execute(DeployerHelpers.Addresses memory addresses) internal override {
    uint8 attempts = 30;
    for (uint256 i = 0; i < attempts; i++) {
      msg.sender.call{value: 0}(new bytes(0));
    }
  }
}

contract Ethereum is WarmUpDeployer {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Ethereum_testnet is WarmUpDeployer {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Ethereum_local is Ethereum {
  function isLocalFork() public pure virtual override returns (bool) {
    return true;
  }
}
