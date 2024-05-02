// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AxelarMainnetChainIds {
  bytes32 public constant FANTOM = keccak256('Fantom');
  bytes32 public constant POLYGON = keccak256('Polygon');
  bytes32 public constant AVALANCHE = keccak256('Avalanche');
  bytes32 public constant ARBITRUM = keccak256('arbitrum');
  bytes32 public constant OPTIMISM = keccak256('optimism');
  bytes32 public constant ETHEREUM = keccak256('Ethereum');
  bytes32 public constant CELO = keccak256('celo');
  bytes32 public constant BINANCE = keccak256('binance');
  bytes32 public constant BASE = keccak256('base');
  bytes32 public constant SCROLL = keccak256('scroll');
}

library AxelarTestnetChainIds {
  bytes32 public constant FANTOM = keccak256('Fantom');
  bytes32 public constant POLYGON = keccak256('Polygon');
  bytes32 public constant AVALANCHE = keccak256('Avalanche');
  bytes32 public constant ARBITRUM = keccak256('arbitrum-sepolia');
  bytes32 public constant OPTIMISM = keccak256('optimism-sepolia');
  bytes32 public constant ETHEREUM = keccak256('ethereum-sepolia');
  bytes32 public constant BASE = keccak256('base-sepolia');
  bytes32 public constant CELO = keccak256('celo');
  bytes32 public constant BINANCE = keccak256('binance');
  bytes32 public constant SCROLL = keccak256('scroll');
}
