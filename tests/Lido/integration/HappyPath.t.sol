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

contract CrossChainControllerStateTest is BaseIntegrationTest {

  address public mockBscDestination;
  address public cccEthAddress;

  event TestWorked(string message);
  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);
  event ConfirmationsUpdated(uint8 newConfirmations, uint256 indexed chainId);

  string private messageToMock = "This is a message to mock";

  uint8 private constant newConfirmations = 2;

  function setUp() override public {
    super.setUp();

    mockBscDestination = address(new MockDestination(crossChainAddresses.bnb.executor));
    cccEthAddress = crossChainAddresses.eth.crossChainController;

    vm.selectFork(ethFork);

    transferLinkTokens(cccEthAddress);
  }

  function test_HappyPath_WithMockDestination_OnBinance() public {
    _happy_path_with_mock_destination(
      bnbFork,
      crossChainAddresses.bnb.executor,
      BINANCE_CHAIN_ID,
      _buildMockUpgradeMotion(mockBscDestination)
    );
  }

  function test_HappyPath_WithCCCReconfigurationOnBinance() public {
    _happy_path_with_ccc_reconfiguration(
      bnbFork,
      crossChainAddresses.bnb.executor,
      BINANCE_CHAIN_ID,
      _buildReconfigurationMotion(crossChainAddresses.bnb.crossChainController, ETHEREUM_CHAIN_ID, newConfirmations)
    );
  }

  function _happy_path_with_mock_destination(
    uint256 _targetForkId,
    address _destination,
    uint256 _destinationChainId,
    bytes memory _message
  ) internal {
    vm.recordLogs();

    // Send DAO motion to the destination executor
    (ExtendedTransaction memory extendedTx) = _sendCrossChainTransactionAsDao(
      cccEthAddress,
      _destination,
      _destinationChainId,
      _message
    );

    _validateTransactionForwardingSuccess(vm.getRecordedLogs(), 4);

    // Switch to the target fork

    vm.selectFork(_targetForkId);

    address[] memory adapters = new address[](4);
    adapters[0] = crossChainAddresses.bnb.ccipAdapter;
    adapters[1] = crossChainAddresses.bnb.lzAdapter;
    adapters[2] = crossChainAddresses.bnb.hlAdapter;
    adapters[3] = crossChainAddresses.bnb.wormholeAdapter;

    vm.recordLogs();

    _receiveDaoCrossChainMessage(crossChainAddresses.bnb.crossChainController, adapters, extendedTx);

    // Check that the message was received and passed to the executor
    uint256 actionId = _getActionsSetQueued(vm.getRecordedLogs());

    // Execute the action received via a.DI
    IExecutorBase executor = IExecutorBase(crossChainAddresses.bnb.executor);

    vm.expectEmit();
    emit TestWorked(messageToMock);

    executor.execute(actionId);

    // Validate that the message was received by the mock destination
    MockDestination mockDestination = MockDestination(mockBscDestination);
    assertEq(mockDestination.message(), messageToMock);
  }

  function _happy_path_with_ccc_reconfiguration(
    uint256 _targetForkId,
    address _destination,
    uint256 _destinationChainId,
    bytes memory _message
  ) internal {
    vm.recordLogs();

    // Send DAO motion to the destination executor
    (ExtendedTransaction memory extendedTx) = _sendCrossChainTransactionAsDao(
      cccEthAddress,
      _destination,
      _destinationChainId,
      _message
    );

    _validateTransactionForwardingSuccess(vm.getRecordedLogs(), 4);

    // Switch to the target fork

    vm.selectFork(_targetForkId);

    address[] memory adapters = new address[](4);
    adapters[0] = crossChainAddresses.bnb.ccipAdapter;
    adapters[1] = crossChainAddresses.bnb.lzAdapter;
    adapters[2] = crossChainAddresses.bnb.hlAdapter;
    adapters[3] = crossChainAddresses.bnb.wormholeAdapter;

    vm.recordLogs();

    _receiveDaoCrossChainMessage(crossChainAddresses.bnb.crossChainController, adapters, extendedTx);

    // Check that the message was received and passed to the executor
    uint256 actionId = _getActionsSetQueued(vm.getRecordedLogs());

    // Validate current configuration for the Ethereum chain
    ICrossChainReceiver crossChainReceiver = ICrossChainReceiver(crossChainAddresses.bnb.crossChainController);
    (ICrossChainReceiver.ReceiverConfiguration memory configuration) = crossChainReceiver.getConfigurationByChain(ETHEREUM_CHAIN_ID);
    assertEq(configuration.requiredConfirmation, 3);

    IExecutorBase executor = IExecutorBase(crossChainAddresses.bnb.executor);

    vm.expectEmit();
    emit ConfirmationsUpdated(newConfirmations, ETHEREUM_CHAIN_ID);

    executor.execute(actionId);

    // Validate that the configuration was updated
    (ICrossChainReceiver.ReceiverConfiguration memory newConfiguration) = crossChainReceiver.getConfigurationByChain(ETHEREUM_CHAIN_ID);
    assertEq(newConfiguration.requiredConfirmation, newConfirmations);
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

  function _buildReconfigurationMotion(
    address _address,
    uint256 _chainId,
    uint8 _confirmations
  ) public pure returns (bytes memory) {
    address[] memory addresses = new address[](1);
    addresses[0] = _address;

    uint256[] memory values = new uint256[](1);
    values[0] = uint256(0);

    string[] memory signatures = new string[](1);
    signatures[0] = 'updateConfirmations((uint256,uint8)[])';

    bytes[] memory calldatas = new bytes[](1);
    ICrossChainReceiver.ConfirmationInput[] memory update = new ICrossChainReceiver.ConfirmationInput[](1);
    update[0] = ICrossChainReceiver.ConfirmationInput({
      chainId: _chainId,
      requiredConfirmations: _confirmations
    });

    calldatas[0] = abi.encode(update);

    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = false;

    return abi.encode(addresses, values, signatures, calldatas, withDelegatecalls);
  }
}
