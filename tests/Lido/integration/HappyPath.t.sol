pragma solidity ^0.8.19;

import 'forge-std/console2.sol';

import {BaseIntegrationTest} from "./BaseIntegrationTest.sol";

import {MockDestination} from "./utils/MockDestination.sol";

import {ICrossChainController} from "../../../src/contracts/interfaces/ICrossChainController.sol";
import {Envelope, EncodedEnvelope} from '../../../src/contracts/libs/EncodingUtils.sol';

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract CrossChainControllerStateTest is BaseIntegrationTest {

  address public mockPolDestination;
  address public mockBscDestination;

  uint256 private immutable POLYGON_CHAIN_ID = 137;
  uint256 private immutable BINANCE_CHAIN_ID = 56;

  address private immutable LINK_TOKEN = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  address private immutable LINK_TOKEN_HOLDER = 0x5Eab1966D5F61E52C22D0279F06f175e36A7181E;

  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);

  function setUp() override public {
    super.setUp();

    mockPolDestination = address(new MockDestination(crossChainAddresses.pol.executor));
    mockBscDestination = address(new MockDestination(crossChainAddresses.bnb.executor));

    vm.selectFork(ethFork);

    getLinkTokens();
  }

  function test_HappyPath_WithMockDestination_OnPolygon() public {
    _happy_path_with_mock_destination(
      polFork,
      mockPolDestination,
      POLYGON_CHAIN_ID,
      getMessage(
        mockPolDestination,
        "Happy path with mock destination on Polygon"
      )
    );
  }

  function test_HappyPath_WithMockDestination_OnBinance() public {
    _happy_path_with_mock_destination(
      bnbFork,
      mockBscDestination,
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

    vm.expectEmit(true, true, false, false);

    (Envelope memory envelope, EncodedEnvelope memory encodedEnvelope) = _registerEnvelope(
      crossChainController.getCurrentEnvelopeNonce(),
      LIDO_DAO_AGENT,
      crossChainAddresses.eth.chainId,
      _destination,
      _destinationChainId,
      _message
    );

    emit EnvelopeRegistered(encodedEnvelope.id, envelope);

    vm.prank(LIDO_DAO_AGENT, ZERO_ADDRESS);
    crossChainController.forwardMessage(
      _destinationChainId,
      _destination,
      getGasLimit(),
      _message
    );
  }

  // Helpers

  function getGasLimit() public view virtual returns (uint256) {
    return 300_000;
  }

  function getLinkTokens() public {
    vm.prank(LINK_TOKEN_HOLDER, ZERO_ADDRESS);
    IERC20(LINK_TOKEN).transfer(crossChainAddresses.eth.crossChainController, 100e18);
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
