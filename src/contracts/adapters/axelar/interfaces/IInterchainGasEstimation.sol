// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {GasEstimationType, GasInfo} from '../libs/GasEstimationTypes.sol';

/**
 * @title IInterchainGasEstimation Interface
 * @notice This is an interface for the InterchainGasEstimation contract
 * which allows for estimating gas fees for cross-chain communication on the Axelar network.
 */
interface IInterchainGasEstimation {
  /**
   * @notice Estimates the gas fee for a cross-chain contract call.
   * @param destinationChain Axelar registered name of the destination chain
   * @param destinationAddress Destination contract address being called
   * @param executionGasLimit The gas limit to be used for the destination contract execution,
   *        e.g. pass in 200k if your app consumes needs upto 200k for this contract call
   * @param params Additional parameters for the gas estimation
   * @return gasEstimate The cross-chain gas estimate, in terms of source chain's native gas token that should be forwarded to the gas service.
   */
  function estimateGasFee(
    string calldata destinationChain,
    string calldata destinationAddress,
    bytes calldata payload,
    uint256 executionGasLimit,
    bytes calldata params
  ) external view returns (uint256 gasEstimate);
}
