// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {AxelarGMPExecutable} from './libs/AxelarGMPExecutable.sol';
import {BaseAxelarAdapter} from './libs/BaseAxelarAdapter.sol';
import {IAxelarGasService} from './interfaces/IAxelarGasService.sol';
import {IAxelarGMPGateway} from './interfaces/IAxelarGMPGateway.sol';
import {Errors} from '../../libs/Errors.sol';
import {ChainIds} from '../../libs/ChainIds.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {StringToAddress, AddressToString} from './libs/AddressString.sol';

contract AxelarAdapter is Ownable, BaseAxelarAdapter, AxelarGMPExecutable {
  IAxelarGasService public gasService;
  address public refundAddress;

  /**
   * @param crossChainController address of the cross chain controller that will use this bridge adapter
   * @param _gateway address of the axelar gateway contract
   * @param _gasService address of the gas service contract
   */
  constructor(
    address crossChainController,
    address _gateway,
    address _gasService,
    address _refundAddress,
    TrustedRemotesConfig[] memory trustedRemotes
  )
    AxelarGMPExecutable(_gateway)
    BaseAdapter(crossChainController, 0, 'Axelar adapter', trustedRemotes)
  {
    require(_gasService != address(0), Errors.INVALID_AXELAR_GAS_SERVICE);
    require(_refundAddress != address(0), Errors.INVALID_AXELAR_REFUND_ADDRESS);

    gasService = IAxelarGasService(_gasService);
    refundAddress = _refundAddress;
  }

  /// @inheritdoc BaseAxelarAdapter
  // @dev this function is used to convert the axelar chain id to the infra chain id
  function axelarToInfraChainId(
    string calldata axelarChainId
  ) public pure virtual override returns (uint256) {
    if (Strings.equal(axelarChainId, 'fantom')) return ChainIds.FANTOM;
    if (Strings.equal(axelarChainId, 'polygon')) return ChainIds.POLYGON;
    if (Strings.equal(axelarChainId, 'avalanche')) return ChainIds.AVALANCHE;
    if (Strings.equal(axelarChainId, 'arbitrum')) return ChainIds.ARBITRUM;
    if (Strings.equal(axelarChainId, 'optimism')) return ChainIds.OPTIMISM;
    if (Strings.equal(axelarChainId, 'ethereum')) return ChainIds.ETHEREUM;
    if (Strings.equal(axelarChainId, 'celo')) return ChainIds.CELO;
    if (Strings.equal(axelarChainId, 'binance')) return ChainIds.BNB;
    if (Strings.equal(axelarChainId, 'base')) return ChainIds.BASE;
    if (Strings.equal(axelarChainId, 'scroll')) return ChainIds.SCROLL;

    return 0;
  }

  /// @inheritdoc BaseAxelarAdapter
  // @dev this function is used to convert the infra chain id to the axelar chain id
  function infraToAxelarChainId(
    uint256 infraChainId
  ) public pure virtual override returns (string memory) {
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
  /**
   * @dev This function is used to forward a message to the destination chain
   * @param receiver - destination adapter contract address
   * @param executionGasLimit - gas limit for the contract call at the destination chain
   * @param destinationChainId - destination chain id
   * @param message - message to be sent to the destination chain
   * @return (address, uint256) - address of the gateway contract and message id
   */
  function forwardMessage(
    address receiver,
    uint256 executionGasLimit,
    uint256 destinationChainId,
    bytes calldata message
  ) external override returns (address, uint256) {
    // 1. retrieve axelar-compatible chain id
    string memory destinationChain = infraToAxelarChainId(destinationChainId);
    require(bytes(destinationChain).length > 0, Errors.DESTINATION_CHAIN_ID_NOT_SUPPORTED);
    require(receiver != address(0), Errors.RECEIVER_NOT_SET);

    string memory stringReceiver = AddressToString.toString(receiver);

    // 2. estimate on-chain gas
    uint256 gasFee = gasService.estimateGasFee(
      destinationChain,
      stringReceiver,
      message,
      executionGasLimit,
      '0x'
    );

    // 3. pay for gas
    gasService.payNativeGasForContractCall{value: gasFee}(
      msg.sender,
      destinationChain,
      stringReceiver,
      message,
      refundAddress
    );

    // 3. forward message
    IAxelarGMPGateway(gatewayAddress).callContract(destinationChain, stringReceiver, message);

    return (gatewayAddress, 0);
  }

  // @inheritdoc AxelarGMPExecutable
  // @dev the cross-chain message receiver for Axelar GMP call
  function _execute(
    bytes32,
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata message
  ) internal override {
    uint256 originChainId = axelarToInfraChainId(sourceChain);
    address trustedSourceAddress = this.getTrustedRemoteByChainId(originChainId);

    if (
      StringToAddress.toAddress(sourceAddress) != trustedSourceAddress &&
      trustedSourceAddress != address(0)
    ) {
      revert(Errors.REMOTE_NOT_TRUSTED);
    }

    _registerReceivedMessage(message, originChainId);
  }
}
