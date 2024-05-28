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

contract HappyPathIntegrationTest is BaseIntegrationTest {

  address public mockDestination;

  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);
  event ConfirmationsUpdated(uint8 newConfirmations, uint256 indexed chainId);

  string private messageToMock = "This is a message to mock";

  uint8 private constant newConfirmations = 2;

  function setUp() override public {
    super.setUp();

    vm.selectFork(ethFork);
    transferLinkTokens(ethCCCAddress);

    vm.selectFork(bnbFork);
    mockDestination = address(new MockDestination(crossChainAddresses.bnb.executorMock));
  }

  function test_HappyPath_WithMockDestination_OnBinance() public {
    _runMockUpdate(
      bnbFork,
      LIDO_DAO_AGENT_FAKE, // DAO Agent 1 - the one after deploy
      ethCCCAddress,
      crossChainAddresses.bnb.executorMock,
      BINANCE_CHAIN_ID,
      bnbAdapters,
      mockDestination,
      messageToMock
    );
  }

  function test_HappyPath_WithReconfiguration_OnBinance() public {
    bytes memory motion = _buildReconfigurationMotion(
      crossChainAddresses.bnb.crossChainController,
      ETHEREUM_CHAIN_ID,
      newConfirmations
    );

    uint256 actionId = _transferMessage(
      bnbFork,
      LIDO_DAO_AGENT_FAKE,
      ethCCCAddress,
      crossChainAddresses.bnb.executorMock,
      BINANCE_CHAIN_ID,
      bnbAdapters,
      motion
    );

    vm.selectFork(bnbFork);

    // Validate current receiver configuration for the Ethereum chain
    ICrossChainReceiver crossChainReceiver = ICrossChainReceiver(crossChainAddresses.bnb.crossChainController);
    (ICrossChainReceiver.ReceiverConfiguration memory configuration) = crossChainReceiver.getConfigurationByChain(ETHEREUM_CHAIN_ID);
    assertEq(configuration.requiredConfirmation, 3);

    // Run the motion
    IExecutorBase executor = IExecutorBase(crossChainAddresses.bnb.executorMock);

    vm.expectEmit();
    emit ConfirmationsUpdated(newConfirmations, ETHEREUM_CHAIN_ID);

    executor.execute(actionId);

    // Validate that the configuration was updated
    (ICrossChainReceiver.ReceiverConfiguration memory newConfiguration) = crossChainReceiver.getConfigurationByChain(ETHEREUM_CHAIN_ID);
    assertEq(newConfiguration.requiredConfirmation, newConfirmations);
  }

  // Helpers

  function _buildReconfigurationMotion(
    address _address,
    uint256 _chainId,
    uint8 _confirmations
  ) internal pure returns (bytes memory) {
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
