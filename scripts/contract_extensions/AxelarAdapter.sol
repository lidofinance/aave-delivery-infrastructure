// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AxelarAdapter} from '../../src/contracts/adapters/axelar/AxelarAdapter.sol';
import {BaseAxelarAdapter} from '../../src/contracts/adapters/axelar/libs/BaseAxelarAdapter.sol';
import {AxelarTestnetChainIds} from '../../src/contracts/adapters/axelar/libs/AxelarChainIds.sol';
import {TestNetChainIds} from './TestNetChainIds.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

contract AxelarAdapterTestnet is AxelarAdapter {
  constructor(
    address crossChainController,
    address gateway,
    address gasService,
    address refundAddress,
    TrustedRemotesConfig[] memory trustedRemotes
  ) AxelarAdapter(crossChainController, gateway, gasService, refundAddress, trustedRemotes) {}

  /// @inheritdoc BaseAxelarAdapter
  // @dev this function is used to convert the axelar chain id to the infra chain id
  function axelarToInfraChainId(
    string calldata axelarChainId
  ) public pure override returns (uint256) {
    bytes32 axelarChainIdHash = keccak256(abi.encodePacked(axelarChainId));

    if (axelarChainIdHash == AxelarTestnetChainIds.FANTOM) return TestNetChainIds.FANTOM_TESTNET;
    if (axelarChainIdHash == AxelarTestnetChainIds.POLYGON) return TestNetChainIds.POLYGON_MUMBAI;
    if (axelarChainIdHash == AxelarTestnetChainIds.AVALANCHE) return TestNetChainIds.AVALANCHE_FUJI;
    if (axelarChainIdHash == AxelarTestnetChainIds.ARBITRUM)
      return TestNetChainIds.ARBITRUM_SEPOLIA;
    if (axelarChainIdHash == AxelarTestnetChainIds.OPTIMISM)
      return TestNetChainIds.OPTIMISM_SEPOLIA;
    if (axelarChainIdHash == AxelarTestnetChainIds.ETHEREUM)
      return TestNetChainIds.ETHEREUM_SEPOLIA;
    if (axelarChainIdHash == AxelarTestnetChainIds.CELO) return TestNetChainIds.CELO_ALFAJORES;
    if (axelarChainIdHash == AxelarTestnetChainIds.BINANCE) return TestNetChainIds.BNB_TESTNET;
    if (axelarChainIdHash == AxelarTestnetChainIds.BASE) return TestNetChainIds.BASE_SEPOLIA;
    if (axelarChainIdHash == AxelarTestnetChainIds.SCROLL) return TestNetChainIds.SCROLL_SEPOLIA;

    return 0;
  }

  /// @inheritdoc BaseAxelarAdapter
  // @dev this function is used to convert the infra chain id to the axelar chain id
  function infraToAxelarChainId(uint256 infraChainId) public pure override returns (string memory) {
    if (infraChainId == TestNetChainIds.FANTOM_TESTNET) return 'Fantom';
    if (infraChainId == TestNetChainIds.POLYGON_MUMBAI) return 'Polygon';
    if (infraChainId == TestNetChainIds.AVALANCHE_FUJI) return 'Avalanche';
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
