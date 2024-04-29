pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';

import {BaseIntegrationTest} from "../BaseIntegrationTest.sol";

import {MockDestination} from "../utils/MockDestination.sol";

import {ICrossChainController} from "../../../src/contracts/interfaces/ICrossChainController.sol";
import {Envelope, EncodedEnvelope} from '../../../src/contracts/libs/EncodingUtils.sol';
import {CrossChainController} from "../../../src/contracts/CrossChainController.sol";
import {IExecutorBase} from "../../../src/Lido/contracts/interfaces/IExecutorBase.sol";

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract CrossChainControllerStateTest is BaseIntegrationTest {

  address public mockBscDestination;

  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);
  event TestWorked(string message);

  function setUp() override public {
    super.setUp();

    mockBscDestination = address(new MockDestination(crossChainAddresses.bnb.executor));

    vm.selectFork(ethFork);

    getLinkTokens();
  }

  function test_HappyPath_WithMockDestination_OnBinance() public {
    _happy_path_with_mock_destination(
      bnbFork,
      crossChainAddresses.bnb.executor,
      BINANCE_CHAIN_ID,
      getMessage(
        mockBscDestination,
        "Happy path with mock destination on Binance"
      )
    );
  }

  function _happy_path_with_mock_destination(
    uint256 _targetForkId,
    address _destination,
    uint256 _destinationChainId,
    bytes memory _message
  ) internal {
    ICrossChainController crossChainController = ICrossChainController(
      crossChainAddresses.eth.crossChainController
    );

    assertEq(crossChainController.getCurrentEnvelopeNonce(), 0);
    assertEq(crossChainController.isSenderApproved(LIDO_DAO_AGENT), true);

    ExtendedTransaction memory extendedTx = _registerExtendedTransaction(
      crossChainController.getCurrentEnvelopeNonce(),
      crossChainController.getCurrentTransactionNonce(),
      LIDO_DAO_AGENT,
      ETHEREUM_CHAIN_ID,
      _destination,
      _destinationChainId,
      _message
    );

    vm.prank(LIDO_DAO_AGENT, ZERO_ADDRESS);
    vm.recordLogs();

    crossChainController.forwardMessage(
      _destinationChainId,
      _destination,
      getGasLimit(),
      _message
    );

    // Check that the transaction failed on all the adapters
    bytes32 signature = keccak256("TransactionForwardingAttempted(bytes32,bytes32,bytes,uint256,address,address,bool,bytes)");
    Vm.Log[] memory entries = vm.getRecordedLogs();

    uint256 count = 0;
    for (uint256 i = 0; i < entries.length; i++) {
      if (entries[i].topics[0] == signature && entries[i].topics[3] == bytes32(uint(1))) {
        count++;
      }
    }

    assertEq(count, 4); // all adapters should succeed

    // Switch to the target fork

    vm.selectFork(_targetForkId);

    // CrossChainController should receive the messages from the adapters

    ICrossChainController targetCrossChainController = ICrossChainController(
      crossChainAddresses.bnb.crossChainController
    );

    address[] memory addresses = new address[](4);
    addresses[0] = crossChainAddresses.bnb.ccipAdapter;
    addresses[1] = crossChainAddresses.bnb.lzAdapter;
    addresses[2] = crossChainAddresses.bnb.hlAdapter;
    addresses[3] = crossChainAddresses.bnb.wormholeAdapter;

    vm.recordLogs();

    for (uint256 i = 0; i < addresses.length; i++) {
      vm.prank(addresses[i], ZERO_ADDRESS);
      targetCrossChainController.receiveCrossChainMessage(
        extendedTx.transactionEncoded,
        extendedTx.envelope.originChainId
      );
    }

    entries = vm.getRecordedLogs();

    signature = keccak256("ActionsSetQueued(uint256,address[],uint256[],string[],bytes[],bool[],uint256)");
    count = 0;
    uint256 actionId;

    for (uint256 i = 0; i < entries.length; i++) {
      if (entries[i].topics[0] == signature) {
        count++;
        actionId = uint256(entries[i].topics[1]);
      }
    }

    assertEq(count, 1); // action should be queued

    IExecutorBase executor = IExecutorBase(crossChainAddresses.bnb.executor);

    vm.expectEmit();

    emit TestWorked("Happy path with mock destination on Binance");

    executor.execute(actionId);

    MockDestination mockDestination = MockDestination(mockBscDestination);

    assertEq(mockDestination.message(), "Happy path with mock destination on Binance");
  }

  // Helpers

  function getGasLimit() public view virtual returns (uint256) {
    return 300_000;
  }

  function getLinkTokens() public {
    vm.prank(ETH_LINK_TOKEN_HOLDER, ZERO_ADDRESS);
    IERC20(ETH_LINK_TOKEN).transfer(crossChainAddresses.eth.crossChainController, 100e18);
  }

  function getMessage(
    address _address,
    string memory _message
  ) public pure returns (bytes memory) {
    address[] memory addresses = new address[](1);
    addresses[0] = _address;

    uint256[] memory values = new uint256[](1);
    values[0] = uint256(0);

    string[] memory signatures = new string[](1);
    signatures[0] = 'test(string)';

    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encode(_message);

    bool[] memory withDelegatecalls = new bool[](1);
    withDelegatecalls[0] = false;

    return abi.encode(addresses, values, signatures, calldatas, withDelegatecalls);
  }
}
