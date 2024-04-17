// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {IAxelarGasService} from './interfaces/IAxelarGasService.sol';
import {IAxelarGMPGateway} from './interfaces/IAxelarGMPGateway.sol';
import {Errors} from '../../libs/Errors.sol';
import {ChainIds} from '../../libs/ChainIds.sol';

contract AxelarAdapter is BaseAdapter, IAxelarAdapter, AxelarGMPExecutable {
  IAxelarGMPGateway public gateway;
  IAxelarGasService public gasService;

  constructor(address gateway, address gasService) AxelarGMPExecutable(gateway) {
    require(gateway != address(0), Errors.INVALID_AXELAR_GATEWAY);
    require(gasService != address(0), Errors.INVALID_AXELAR_GAS_SERVICE);
    gateway = IAxelarGMPGateway(gateway);
    gasService = IAxelarGasService(gasService);
  }

  /// @inheritdoc IAxelarAdapter
  function nativeToInfraChainId(string calldata nativeChainId) public view returns (string) {
    if (nativeChainId == 'fantom') return ChainIds.FANTOM;
    if (nativeChainId == 'polygon') return ChainIds.POLYGON;
    if (nativeChainId == 'avalanche') return ChainIds.AVALANCHE;
    if (nativeChainId == 'arbitrum') return ChainIds.ARBITRUM;
    if (nativeChainId == 'optimism') return ChainIds.OPTIMISM;
    if (nativeChainId == 'ethereum') return ChainIds.ETHEREUM;
    if (nativeChainId == 'celo') return ChainIds.CELO;
    if (nativeChainId == 'binance') return ChainIds.BNB;
    if (nativeChainId == 'base') return ChainIds.BASE;
    if (nativeChainId == 'scroll') return ChainIds.SCROLL;

    return 0;
  }

  /// @inheritdoc IAxelarAdapter
  function infraToNativeChainId(uint256 infraChainId) public view returns (string) {
    if (infraChainId == ChainIds.FANTOM) return 'fantom';
    if (infraChainId == ChainIds.POLYGON) return 'polygon';
    if (infraChainId == ChainIds.AVALANCHE) return 'avalanche';
    if (infraChainId == ChainIds.ARBITRUM) return 'arbitrum';
    if (infraChainId == ChainIds.OPTIMISM) return 'optimism';
    if (infraChainId == ChainIds.ETHEREUM) return 'ethereum';
    if (infraChainId == ChainIds.CELO) return 'celo';
    if (infraChainId == ChainIds.BNB) return 'binance';
    if (infraChainId == ChainIds.BASE) return 'base';
    if (infraChainId == ChainIds.SCROLL) return 'scroll';

    return '';
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 executionGasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external override returns (address, uint256) {
    // 1. retrieve axelar-compatible chain id
    string memory destinationChain = infraToNativeChainId(destinationChainId);
    require(bytes(destinationChain).length > 0, Errors.DESTINATION_CHAIN_ID_NOT_SUPPORTED);

    // 2. estimate on-chain gas
    uint256 gasEstimate = gasService.estimateGasFee(
      destinationChain,
      receiver,
      message,
      executionGasLimit,
      '0x'
    );

    // 3. forward message
    gateway.callContract{value: gasEstimate}(destinationChain, receiver, message);
  }

  // @inheritdoc AxelarGMPExecutable
  // @dev This function is called by the Axelar Executor service after validating the command.
  function _execute(
    bytes32 commandId,
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  ) internal override {
    uint256 originChainId = nativeToInfraChainId(sourceChain);
    _registerReceivedMessage(_message, originChainId);
  }
}
