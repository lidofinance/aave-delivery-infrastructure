// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import '../BaseScript.sol';

abstract contract FundDeployer is BaseScript {
  function _execute(DeployerHelpers.Addresses memory addresses) internal override {
    uint256 value = 10 ether;

    // Deployer
    payable(0x77d302662a84c0924a8290f72200e1F43D28430F).call{value: value}(new bytes(0));

    // Voter
    payable(0x6666652521e95a1b0A46EE682Ac89e2E54cfCcEd).call{value: value}(new bytes(0));
  }
}

contract Ethereum is FundDeployer {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Ethereum_testnet is FundDeployer {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Ethereum_local is Ethereum {
  function isLocalFork() public pure virtual override returns (bool) {
    return true;
  }
}

contract Binance is FundDeployer {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Binance_testnet is FundDeployer {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}

contract Binance_local is Binance {
  function isLocalFork() public pure virtual override returns (bool) {
    return true;
  }
}

