// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AxelarAdapter} from '../../src/contracts/adapters/axelar/AxelarAdapter.sol';
import {BaseAxelarAdapter} from '../../src/contracts/adapters/axelar/libs/BaseAxelarAdapter.sol';
import {TestNetChainIds} from './TestNetChainIds.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract AxelarAdapterTestnet is AxelarAdapter {
  constructor(address gateway, address gasService) AxelarAdapter(gateway, gasService) {}

  /// @inheritdoc BaseAxelarAdapter
  // @dev this function is used to convert the axelar chain id to the infra chain id
  function axelarToInfraChainId(
    string calldata axelarChainId
  ) public pure override returns (uint256) {
    if (Strings.equal(axelarChainId, 'fantom')) return TestNetChainIds.FANTOM_TESTNET;
    if (Strings.equal(axelarChainId, 'polygon')) return TestNetChainIds.POLYGON_MUMBAI;
    if (Strings.equal(axelarChainId, 'avalanche')) return TestNetChainIds.AVALANCHE_FUJI;
    if (Strings.equal(axelarChainId, 'arbitrum-sepolia')) return TestNetChainIds.ARBITRUM_SEPOLIA;
    if (Strings.equal(axelarChainId, 'optimism-sepolia')) return TestNetChainIds.OPTIMISM_SEPOLIA;
    if (Strings.equal(axelarChainId, 'ethereum-sepolia')) return TestNetChainIds.ETHEREUM_SEPOLIA;
    if (Strings.equal(axelarChainId, 'base-sepolia')) return TestNetChainIds.BASE_SEPOLIA;
    if (Strings.equal(axelarChainId, 'celo')) return TestNetChainIds.CELO_ALFAJORES;
    if (Strings.equal(axelarChainId, 'binance')) return TestNetChainIds.BNB_TESTNET;
    if (Strings.equal(axelarChainId, 'scroll')) return TestNetChainIds.SCROLL_SEPOLIA;

    return 0;
  }

  /// @inheritdoc BaseAxelarAdapter
  // @dev this function is used to convert the infra chain id to the axelar chain id
  function infraToAxelarChainId(uint256 infraChainId) public pure override returns (string memory) {
    if (infraChainId == TestNetChainIds.FANTOM_TESTNET) return 'fantom';
    if (infraChainId == TestNetChainIds.POLYGON_MUMBAI) return 'polygon';
    if (infraChainId == TestNetChainIds.AVALANCHE_FUJI) return 'avalanche';
    if (infraChainId == TestNetChainIds.ARBITRUM_SEPOLIA) return 'arbitrum-sepolia';
    if (infraChainId == TestNetChainIds.OPTIMISM_SEPOLIA) return 'optimism-sepolia';
    if (infraChainId == TestNetChainIds.ETHEREUM_SEPOLIA) return 'ethereum-sepolia';
    if (infraChainId == TestNetChainIds.BASE_SEPOLIA) return 'base-sepolia';
    if (infraChainId == TestNetChainIds.CELO_ALFAJORES) return 'celo';
    if (infraChainId == TestNetChainIds.BNB_TESTNET) return 'binance';
    if (infraChainId == TestNetChainIds.SCROLL_SEPOLIA) return 'scroll';

    return '';
  }
}
