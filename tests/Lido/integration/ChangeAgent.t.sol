pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';

import {BaseIntegrationTest} from "../BaseIntegrationTest.sol";

import {ICrossChainController} from "../../../src/contracts/interfaces/ICrossChainController.sol";
import {ICrossChainReceiver} from "../../../src/contracts/interfaces/ICrossChainReceiver.sol";
import {Envelope, EncodedEnvelope} from '../../../src/contracts/libs/EncodingUtils.sol';
import {CrossChainController} from "../../../src/contracts/CrossChainController.sol";
import {IExecutorBase} from "../../../src/Lido/contracts/interfaces/IExecutorBase.sol";

import {MockDestination} from "../utils/MockDestination.sol";

contract ChangeAgentIntegrationTest is BaseIntegrationTest {

  address public mockDestination;
  address public cccEthAddress;

  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);
  event ConfirmationsUpdated(uint8 newConfirmations, uint256 indexed chainId);

  string private messageToMock = "This is a message to mock";

  uint8 private constant newConfirmations = 2;

  function setUp() override public {
    super.setUp();

    mockDestination = address(new MockDestination(crossChainAddresses.bnb.executor));
    cccEthAddress = crossChainAddresses.eth.crossChainController;

    vm.selectFork(ethFork);

    transferLinkTokens(cccEthAddress);
  }

  function test_ChangeAgent_OnBinance() public {
    // Validate that setup works with DAO Agent 1
    _run_mock_update(
      bnbFork,
      cccEthAddress,
      crossChainAddresses.bnb.executor,
      BINANCE_CHAIN_ID,
      mockDestination,
      messageToMock
    );
  }
}
