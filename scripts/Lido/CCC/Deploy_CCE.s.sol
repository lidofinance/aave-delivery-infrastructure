// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {CrossChainExecutor} from "../../../src/Lido/contracts/CrossChainExecutor.sol";

import '../BaseScript.sol';

abstract contract BaseExecutorDeployment is BaseScript {
  function getEthereumGovernanceExecutorAddress() public view virtual returns (address) {
    return address(0);
  }

  function getEthereumGovernanceChainId() public view virtual returns (uint256) {
    return 0;
  }

  function _execute(DeployerHelpers.Addresses memory addresses) internal override {
    addresses.executor = address(new CrossChainExecutor(
      addresses.crossChainController,
      getEthereumGovernanceExecutorAddress(),
      getEthereumGovernanceChainId(),
      0,              // delay
      86400,          // gracePeriod
      0,              // minimumDelay
      1,              // maximumDelay
      Constants.ZERO  // guardian
    ));
  }
}

abstract contract MainnetExecutor is BaseExecutorDeployment {
  // https://docs.lido.fi/deployed-contracts/#dao-contracts Aragon Agent
  function getEthereumGovernanceExecutorAddress() public view virtual override returns (address) {
    // return Constants.LIDO_DAO_AGENT;
    return Constants.LIDO_DAO_AGENT_FAKE;
  }

  function getEthereumGovernanceChainId() public view virtual override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Polygon is MainnetExecutor {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Binance is MainnetExecutor {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return ChainIds.BNB;
  }
}

abstract contract TestnetExecutor is BaseExecutorDeployment {
  // https://docs.lido.fi/deployed-contracts/sepolia#dao-contracts Aragon Agent
  function getEthereumGovernanceExecutorAddress() public view virtual override returns (address) {
    return 0x32A0E5828B62AAb932362a4816ae03b860b65e83;
  }

  function getEthereumGovernanceChainId() public view virtual override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Polygon_testnet is TestnetExecutor {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return TestNetChainIds.POLYGON_MUMBAI;
  }
}

contract Binance_testnet is TestnetExecutor {
  function TRANSACTION_NETWORK() public pure virtual override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}

contract Polygon_local is Polygon {
  function isLocalFork() public pure virtual override returns (bool) {
    return true;
  }
}

contract Binance_local is Binance {
  function isLocalFork() public pure virtual override returns (bool) {
    return true;
  }
}
