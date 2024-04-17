// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAxelarAdapter
 */
interface IAxelarAdapter {
  function nativeToInfraChainId(string calldata nativeChainId) external view returns (uint256);

  function infraToNativeChainId(uint256 infraChainId) external view returns (string calldata);
}
