// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {GasInfo} from '../libs/GasEstimationTypes.sol';
import {IInterchainGasEstimation} from './IInterchainGasEstimation.sol';

/**
 * @title IAxelarGasService Interface
 * @notice This is an interface for the AxelarGasService contract which manages gas payments
 * and refunds for cross-chain communication on the Axelar network.
 * @dev This interface inherits IUpgradable
 */
interface IAxelarGasService is IInterchainGasEstimation {
  /**
   * @notice Pay for gas using native currency for a contract call on a destination chain.
   * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
   * @param sender The address making the payment
   * @param destinationChain The target chain where the contract call will be made
   * @param destinationAddress The target address on the destination chain
   * @param payload Data payload for the contract call
   * @param refundAddress The address where refunds, if any, should be sent
   */
  function payNativeGasForContractCall(
    address sender,
    string calldata destinationChain,
    string calldata destinationAddress,
    bytes calldata payload,
    address refundAddress
  ) external payable;
}
