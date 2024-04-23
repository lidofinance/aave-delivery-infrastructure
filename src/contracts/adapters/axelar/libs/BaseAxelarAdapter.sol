// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseAdapter, IBaseAdapter} from '../../BaseAdapter.sol';

/**
 * @title IAxelarAdapter
 */
abstract contract BaseAxelarAdapter is BaseAdapter {
  function axelarToInfraChainId(
    string calldata axelarChainId
  ) public pure virtual returns (uint256);

  function infraToAxelarChainId(uint256 infraChainId) public pure virtual returns (string memory);

  function infraToNativeChainId(uint256) public pure override returns (uint256) {
    return 0;
  }

  function nativeToInfraChainId(uint256) public pure override returns (uint256) {
    return 0;
  }
}
