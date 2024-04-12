// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {CrossChainExecutor} from "../../../src/Lido/contracts/CrossChainExecutor.sol";

import '../BaseScript.sol';

abstract contract BaseExecutor is BaseScript {
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
      0,          // delay
      86400,      // gracePeriod
      0,          // minimumDelay
      1,          // maximumDelay
      address(0)  // guardian
    ));
  }
}

abstract contract MainnetExecutor is BaseExecutor {
  // https://docs.lido.fi/deployed-contracts/#dao-contracts Aragon Agent
  function getEthereumGovernanceExecutorAddress() public view virtual override returns (address) {
    return 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c;
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

abstract contract TestnetExecutor is BaseExecutor {
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