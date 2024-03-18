// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IBaseReceiverPortal} from "../../../src/contracts/interfaces/IBaseReceiverPortal.sol";

import {BridgeExecutorBase} from "./BridgeExecutorBase.sol";

/**
 * @title PolygonBridgeExecutor
 * @author Aave
 * @notice Implementation of the Polygon Bridge Executor, able to receive cross-chain transactions from Ethereum
 * @dev Queuing an ActionsSet into this Executor can only be done by the FxChild and after passing the EthereumGovernanceExecutor check
 * as the FxRoot sender
 */
contract CrossChainExecutor is BridgeExecutorBase, IBaseReceiverPortal {

  /**
   * @dev Address of the CrossChainController contract on the current chain.
   */
  address private immutable _crossChainController;

  /**
   * @dev Address of the DAO Agent contract on the root chain.
   */
  address private immutable _ethereumGovernanceExecutor;

  /**
   * @dev Root Chain ID of the DAO Agent contract, must be 1 for Ethereum.
   */
  uint256 private immutable _ethereumGovernanceChainId;

  error InvalidCrossChainController();
  error InvalidEthereumGovernanceExecutor();
  error InvalidEthereumGovernanceChainId();
  error InvalidCaller();
  error InvalidSenderAddress();
  error InvalidSenderChainId();

  event MessageReceived(address indexed originSender, uint256 indexed originChainId, bytes message);

  /**
   * @dev Only allows the CrossChainController to call the function
   */
  modifier onlyCrossChainController() {
    if (msg.sender != _crossChainController) revert InvalidCaller();
    _;
  }

  /**
   * @dev Constructor
   *
   * @param crossChainController - Address of the CrossChainController contract on the current chain
   * @param ethereumGovernanceExecutor - Address of the DAO Aragon Agent contract on the root chain
   * @param ethereumGovernanceChainId - Chain ID of the DAO Aragon Agent contract
   * @param delay - The delay before which an actions set can be executed
   * @param gracePeriod - The time period after a delay during which an actions set can be executed
   * @param minimumDelay - The minimum bound a delay can be set to
   * @param maximumDelay - The maximum bound a delay can be set to
   * @param guardian - The address of the guardian, which can cancel queued proposals (can be zero)
   */
  constructor(
    address crossChainController,
    address ethereumGovernanceExecutor,
    uint256 ethereumGovernanceChainId,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    address guardian
  ) BridgeExecutorBase(delay, gracePeriod, minimumDelay, maximumDelay, guardian) {
    if (crossChainController == address(0)) revert InvalidCrossChainController();
    if (ethereumGovernanceExecutor == address(0)) revert InvalidEthereumGovernanceExecutor();
    if (ethereumGovernanceChainId == 0) revert InvalidEthereumGovernanceChainId();

    _crossChainController = crossChainController;
    _ethereumGovernanceExecutor = ethereumGovernanceExecutor;
    _ethereumGovernanceChainId = ethereumGovernanceChainId;
  }

  /**
   * @notice method called by CrossChainController when a message has been confirmed
   * @param originSender address of the sender of the bridged message
   * @param originChainId id of the chain where the message originated
   * @param message bytes bridged containing the desired information
   */
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory message
  ) external override onlyCrossChainController {
    if (originSender != _ethereumGovernanceExecutor) revert InvalidSenderAddress();
    if (originChainId != _ethereumGovernanceChainId) revert InvalidSenderChainId();

    emit MessageReceived(originSender, originChainId, message);

    _receiveCrossChainMessage(message);
  }

  /**
   * @notice method called by receiveCrossChainMessage to put the message into the queue
   * @param data bytes containing the message to be queued
   */
  function _receiveCrossChainMessage(bytes memory data) internal {
    address[] memory targets;
    uint256[] memory values;
    string[] memory signatures;
    bytes[] memory calldatas;
    bool[] memory withDelegatecalls;

    (targets, values, signatures, calldatas, withDelegatecalls) = abi.decode(
      data,
      (address[], uint256[], string[], bytes[], bool[])
    );

    _queue(targets, values, signatures, calldatas, withDelegatecalls);
  }

  /**
   * @notice Returns the address of the Ethereum Governance Executor
   * @return The address of the EthereumGovernanceExecutor
   **/
  function getEthereumGovernanceExecutor() external view returns (address) {
    return _ethereumGovernanceExecutor;
  }

  /**
   * @notice Returns the chain ID of the Ethereum Governance Executor
   * @return The chain ID of the EthereumGovernanceExecutor
   **/
  function getEthereumGovernanceChainId() external view returns (uint256) {
    return _ethereumGovernanceChainId;
  }

  /**
   * @notice Returns the address of the CrossChainController
   * @return The address of the CrossChainController
   **/
  function getCrossChainController() external view returns (address) {
    return _crossChainController;
  }
}
