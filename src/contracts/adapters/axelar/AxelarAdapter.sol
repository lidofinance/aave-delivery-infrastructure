// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {Errors} from '../../libs/Errors.sol';
import {ChainIds} from '../../libs/ChainIds.sol';

contract AxelarAdapter is BaseAdapter {
  address public gateway;
  address public gasService;

  constructor(address gateway, address gasService) {
    require(gateway != address(0), Errors.INVALID_AXELAR_GATEWAY);
    require(gasService != address(0), Errors.INVALID_AXELAR_GAS_SERVICE);
    gateway = gateway;
    gasService = gasService;
  }

  function nativeToInfraChainId(uint256 nativeChainId) public view override returns (uint256) {}

  function infraToNativeChainId(uint256 infraChainId) public view override returns (uint256) {}

  function forwardMessage(
    address receiver,
    uint256 executionGasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external override returns (address, uint256) {}
}
