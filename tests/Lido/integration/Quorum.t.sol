pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';

import {BaseIntegrationTest} from "../BaseIntegrationTest.sol";

import {MockDestination} from "../utils/MockDestination.sol";

import {ICrossChainController} from "../../../src/contracts/interfaces/ICrossChainController.sol";
import {ICrossChainReceiver} from "../../../src/contracts/interfaces/ICrossChainReceiver.sol";
import {Envelope, EncodedEnvelope} from '../../../src/contracts/libs/EncodingUtils.sol';
import {CrossChainController} from "../../../src/contracts/CrossChainController.sol";
import {IExecutorBase} from "../../../src/Lido/contracts/interfaces/IExecutorBase.sol";
import {Transaction} from '../../../src/contracts/libs/EncodingUtils.sol';

contract CrossChainControllerStateTest is BaseIntegrationTest {

  address public mockBscDestination;
  address public cccEthAddress;

  event TestWorked(string message);
  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);
  event ConfirmationsUpdated(uint8 newConfirmations, uint256 indexed chainId);

  event TransactionReceived(
    bytes32 transactionId,
    bytes32 indexed envelopeId,
    uint256 indexed originChainId,
    Transaction transaction,
    address indexed bridgeAdapter,
    uint8 confirmations
  );

  event EnvelopeDeliveryAttempted(bytes32 envelopeId, Envelope envelope, bool isDelivered);

  string private messageToMock = "This is a message to mock";

  function setUp() override public {
    super.setUp();

    mockBscDestination = address(new MockDestination(crossChainAddresses.bnb.executor));
    cccEthAddress = crossChainAddresses.eth.crossChainController;

    vm.selectFork(ethFork);

    transferLinkTokens(cccEthAddress);
  }

  function test_Quorum() public {
    vm.recordLogs();

    // Send DAO motion to the destination executor
    (ExtendedTransaction memory extendedTx) = _sendCrossChainTransactionAsDao(
      cccEthAddress,
      crossChainAddresses.bnb.executor,
      BINANCE_CHAIN_ID,
      _buildMockUpgradeMotion(mockBscDestination)
    );

    _validateTransactionForwardingSuccess(vm.getRecordedLogs(), 4);

    // Switch to the target fork (Binance for example)

    vm.selectFork(bnbFork);

    IExecutorBase targetExecutor = IExecutorBase(crossChainAddresses.bnb.executor);
    ICrossChainController targetCrossChainController = ICrossChainController(crossChainAddresses.bnb.crossChainController);

    vm.expectEmit();

    emit TransactionReceived(
      extendedTx.transactionId,
      extendedTx.envelopeId,
      extendedTx.envelope.originChainId,
      extendedTx.transaction,
      crossChainAddresses.bnb.ccipAdapter,
      1
    );

    // Simulate 1/4 of the quorum
    vm.prank(crossChainAddresses.bnb.ccipAdapter, ZERO_ADDRESS);
    targetCrossChainController.receiveCrossChainMessage(
      extendedTx.transactionEncoded,
      extendedTx.envelope.originChainId
    );

    assertEq(targetExecutor.getActionsSetCount(), 0);

    emit TransactionReceived(
      extendedTx.transactionId,
      extendedTx.envelopeId,
      extendedTx.envelope.originChainId,
      extendedTx.transaction,
      crossChainAddresses.bnb.lzAdapter,
      2
    );

    // Simulate 2/4 of the quorum
    vm.prank(crossChainAddresses.bnb.lzAdapter, ZERO_ADDRESS);
    targetCrossChainController.receiveCrossChainMessage(
      extendedTx.transactionEncoded,
      extendedTx.envelope.originChainId
    );

    assertEq(targetExecutor.getActionsSetCount(), 0);

    emit TransactionReceived(
      extendedTx.transactionId,
      extendedTx.envelopeId,
      extendedTx.envelope.originChainId,
      extendedTx.transaction,
      crossChainAddresses.bnb.hlAdapter,
      3
    );

    emit EnvelopeDeliveryAttempted(
      extendedTx.envelopeId,
      extendedTx.envelope,
      true
    );

    // Simulate 3/4 of the quorum (pass)
    vm.prank(crossChainAddresses.bnb.hlAdapter, ZERO_ADDRESS);
    targetCrossChainController.receiveCrossChainMessage(
      extendedTx.transactionEncoded,
      extendedTx.envelope.originChainId
    );

    assertEq(targetExecutor.getActionsSetCount(), 1);

    // Check that the message was received and passed to the executor
    uint256 actionId = _getActionsSetQueued(vm.getRecordedLogs());

    // Execute the action received via a.DI
    vm.expectEmit();
    emit TestWorked(messageToMock);

    targetExecutor.execute(actionId);

    // Validate that the message was received by the mock destination
    MockDestination mockDestination = MockDestination(mockBscDestination);
    assertEq(mockDestination.message(), messageToMock);

    emit TransactionReceived(
      extendedTx.transactionId,
      extendedTx.envelopeId,
      extendedTx.envelope.originChainId,
      extendedTx.transaction,
      crossChainAddresses.bnb.wormholeAdapter,
      4
    );

    // Simulate 4/4 of the quorum
    vm.prank(crossChainAddresses.bnb.wormholeAdapter, ZERO_ADDRESS);
    targetCrossChainController.receiveCrossChainMessage(
      extendedTx.transactionEncoded,
      extendedTx.envelope.originChainId
    );

    assertEq(targetExecutor.getActionsSetCount(), 1); // should not change
  }

  function _buildMockUpgradeMotion(
    address _address
  ) public view returns (bytes memory) {
    address[] memory addresses = new address[](1);
    addresses[0] = _address;

    uint256[] memory values = new uint256[](1);
    values[0] = uint256(0);

    string[] memory signatures = new string[](1);
    signatures[0] = 'test(string)';

    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encode(messageToMock);

    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = false;

    return abi.encode(addresses, values, signatures, calldatas, withDelegatecalls);
  }
}
