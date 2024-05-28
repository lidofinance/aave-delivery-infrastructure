pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Ownable} from "solidity-utils/contracts/oz-common/Ownable.sol";
import {OwnableWithGuardian} from "solidity-utils/contracts/access-control/OwnableWithGuardian.sol";
import {IRescuable} from "solidity-utils/contracts/utils/interfaces/IRescuable.sol";

import {BaseIntegrationTest} from "../BaseIntegrationTest.sol";

import {CrossChainController} from "../../../src/contracts/CrossChainController.sol";
import {ICrossChainController} from "../../../src/contracts/interfaces/ICrossChainController.sol";
import {ICrossChainReceiver} from "../../../src/contracts/interfaces/ICrossChainReceiver.sol";
import {ICrossChainForwarder} from "../../../src/contracts/interfaces/ICrossChainForwarder.sol";

import {Envelope, EncodedEnvelope} from '../../../src/contracts/libs/EncodingUtils.sol';
import {Errors} from "../../../src/contracts/libs/Errors.sol";

import {IExecutorBase} from "../../../src/Lido/contracts/interfaces/IExecutorBase.sol";
import {CrossChainExecutor} from "../../../src/Lido/contracts/CrossChainExecutor.sol";

import {MockDestination} from "../utils/MockDestination.sol";

contract ChangeAgentIntegrationTest is BaseIntegrationTest {

  address public originalMockDestination;
  address public upgradedExecutorBnbAddress;
  address public upgradedMockDestination;

  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);
  event ConfirmationsUpdated(uint8 newConfirmations, uint256 indexed chainId);

  string private messageToMock = "This is a message to mock";

  uint8 private constant newConfirmations = 2;

  function setUp() override public {
    super.setUp();

    vm.selectFork(ethFork);
    transferLinkTokens(ethCCCAddress);

    vm.selectFork(bnbFork);
    originalMockDestination = address(new MockDestination(crossChainAddresses.bnb.executorMock));
  }

  function test_ChangeAgent_OnBinance() public {
    _runMockUpdate(
      bnbFork,
      LIDO_DAO_AGENT_FAKE, // DAO Agent 1 - the one after deploy
      ethCCCAddress,
      crossChainAddresses.bnb.executorMock,
      BINANCE_CHAIN_ID,
      bnbAdapters,
      originalMockDestination,
      messageToMock
    );

    _runUnauthorizedUpdate(
      LIDO_DAO_AGENT, // DAO Agent 2 - the real one
      ethCCCAddress,
      crossChainAddresses.bnb.executorMock,
      BINANCE_CHAIN_ID,
      originalMockDestination,
      messageToMock
    );

    _deployNewBinanceExecutorAndMock();

    _transferOwnershipOnBinance();

    _transferOwnershipOnEthereum();

    _runMockUpdate(
      bnbFork,
      LIDO_DAO_AGENT, // DAO Agent 2 - the real one
      ethCCCAddress,
      upgradedExecutorBnbAddress,
      BINANCE_CHAIN_ID,
      bnbAdapters,
      upgradedMockDestination,
      messageToMock
    );

    // Validate that old sender is not approved
    _runUnauthorizedUpdate(
      LIDO_DAO_AGENT_FAKE,
      ethCCCAddress,
      crossChainAddresses.bnb.executorMock,
      BINANCE_CHAIN_ID,
      originalMockDestination,
      messageToMock
    );

    // Validate that old sender can't utilize the old executor
    _runUnauthorizedUpdate(
      LIDO_DAO_AGENT_FAKE,
      ethCCCAddress,
      upgradedExecutorBnbAddress,
      BINANCE_CHAIN_ID,
      upgradedMockDestination,
      messageToMock
    );
  }

  function _deployNewBinanceExecutorAndMock() internal {
    vm.selectFork(bnbFork);

    // Deploy new BSC side executor for the new DAO agent
    upgradedExecutorBnbAddress = address(new CrossChainExecutor(
      crossChainAddresses.bnb.crossChainController,
      LIDO_DAO_AGENT,
      ETHEREUM_CHAIN_ID,
      0,          // delay
      86400,      // gracePeriod
      0,          // minimumDelay
      1,          // maximumDelay
      address(0)  // guardian
    ));

    upgradedMockDestination = address(new MockDestination(upgradedExecutorBnbAddress));
  }

  /**
    * @notice Run a an a.DI setup upgrade to pass ownership to the new DAO agent
    */
  function _transferOwnershipOnBinance() internal {
    bytes memory motion = _buildBnbOwnershipTransferMotion();

    uint256 actionId = _transferMessage(
      bnbFork,
      LIDO_DAO_AGENT_FAKE, // DAO Agent 1 - the one after deploy
      ethCCCAddress,
      crossChainAddresses.bnb.executorMock, // The original executor
      BINANCE_CHAIN_ID,
      bnbAdapters,
      motion
    );

    vm.selectFork(bnbFork);

    // Validate that the ProxyAdmin owner is the original executor
    address proxyAdminOwner = Ownable(crossChainAddresses.bnb.proxyAdmin).owner();
    assertEq(proxyAdminOwner, crossChainAddresses.bnb.executorMock, "ProxyAdmin owner should be set to original executor");

    // Run the motion
    IExecutorBase executor = IExecutorBase(crossChainAddresses.bnb.executorMock);
    executor.execute(actionId);

    // Validate that the ownership was transferred
    ProxyAdmin proxyAdminContract = ProxyAdmin(crossChainAddresses.bnb.proxyAdmin);
    ITransparentUpgradeableProxy cccProxy = ITransparentUpgradeableProxy(crossChainAddresses.bnb.crossChainController);

    proxyAdminOwner = Ownable(crossChainAddresses.bnb.proxyAdmin).owner();
    address proxyImp = proxyAdminContract.getProxyImplementation(cccProxy);
    address proxyAdminAddress = proxyAdminContract.getProxyAdmin(cccProxy);

    assertEq(proxyAdminOwner, upgradedExecutorBnbAddress, "ProxyAdmin owner should be updated new executor");
    assertEq(proxyAdminAddress, crossChainAddresses.bnb.proxyAdmin, "ProxyAdmin for CrossChainController should be ProxyAdmin");
    assertEq(proxyImp, crossChainAddresses.bnb.crossChainControllerImpl, "CrossChainController implementation should be CrossChainControllerImpl");
  }

  function _transferOwnershipOnEthereum() internal {
    vm.selectFork(ethFork);
    vm.startPrank(LIDO_DAO_AGENT_FAKE, ZERO_ADDRESS);

    // Swap approved senders
    address[] memory sendersToApprove = new address[](1);
    sendersToApprove[0] = LIDO_DAO_AGENT;

    ICrossChainForwarder(ethCCCAddress).approveSenders(sendersToApprove);

    address[] memory sendersToRemove = new address[](1);
    sendersToRemove[0] = LIDO_DAO_AGENT_FAKE;

    ICrossChainForwarder(ethCCCAddress).removeSenders(sendersToRemove);

    // Transfer ownership of the CrossChainController and ProxyAdmin to the new DAO agent
    Ownable(crossChainAddresses.eth.crossChainController).transferOwnership(LIDO_DAO_AGENT);
    Ownable(crossChainAddresses.eth.proxyAdmin).transferOwnership(LIDO_DAO_AGENT);

    vm.stopPrank();
  }

  /**
    * @notice Run a motion that should revert
    *
    * @param _daoAgent The DAO agent address
    * @param _crossChainController The cross chain controller address
    * @param _executor The executor address
    * @param _chainId The chain ID
    * @param _mockDestination The mock destination address
    * @param _message The message to send
    */
  function _runUnauthorizedUpdate(
    address _daoAgent,
    address _crossChainController,
    address _executor,
    uint256 _chainId,
    address _mockDestination,
    string memory _message
  ) internal {
    vm.selectFork(ethFork);

    ICrossChainController crossChainController = ICrossChainController(_crossChainController);

    assertEq(crossChainController.isSenderApproved(_daoAgent), false);

    vm.expectRevert(bytes(Errors.CALLER_IS_NOT_APPROVED_SENDER));
    crossChainController.forwardMessage(
      _chainId,
      _executor,
      getGasLimit(),
      _buildMockUpgradeMotion(_mockDestination, _message)
    );
  }

  function _buildBnbOwnershipTransferMotion() internal view returns (bytes memory) {
    address[] memory addresses = new address[](2);
    addresses[0] = crossChainAddresses.bnb.crossChainController;
    addresses[1] = crossChainAddresses.bnb.proxyAdmin;

    uint256[] memory values = new uint256[](2);
    values[0] = uint256(0);
    values[1] = uint256(0);

    string[] memory signatures = new string[](2);
    signatures[0] = 'transferOwnership(address)';
    signatures[1] = 'transferOwnership(address)';

    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = abi.encode(upgradedExecutorBnbAddress);
    calldatas[1] = abi.encode(upgradedExecutorBnbAddress);

    bool[] memory withDelegatecalls = new bool[](2);
    withDelegatecalls[0] = false;
    withDelegatecalls[1] = false;

    return abi.encode(addresses, values, signatures, calldatas, withDelegatecalls);
  }
}
