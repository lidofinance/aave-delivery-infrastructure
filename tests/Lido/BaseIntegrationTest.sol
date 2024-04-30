pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';
import 'forge-std/StdJson.sol';

import {BaseTest} from "../BaseTest.sol";

import {Envelope, EncodedEnvelope, Transaction, EncodedTransaction} from '../../src/contracts/libs/EncodingUtils.sol';
import {ICrossChainController} from "../../src/contracts/interfaces/ICrossChainController.sol";

import {BaseTestHelpers} from "./BaseTestHelpers.sol";

contract BaseIntegrationTest is BaseTest, BaseTestHelpers {
  using stdJson for string;

  string ENV = vm.envString('ENV');

  uint256 public ethFork;
  uint256 public bnbFork;

  struct Addresses {
    address ccipAdapter;
    uint256 chainId;
    address crossChainController;
    address crossChainControllerImpl;
    address guardian;
    address hlAdapter;
    address lzAdapter;
    address mockDestination;
    address owner;
    address proxyAdmin;
    address proxyFactory;
    address wormholeAdapter;
    address executor;
  }

  struct CrossChainAddresses {
    Addresses eth;
    Addresses bnb;
  }

  struct CrossChainAddressFiles {
    string eth;
    string bnb;
  }

  CrossChainAddresses internal crossChainAddresses;

  function _getDeploymentFiles() internal view returns (CrossChainAddressFiles memory) {
    if (keccak256(abi.encodePacked(ENV)) == keccak256(abi.encodePacked("local"))) {
      return CrossChainAddressFiles({
        eth: './deployments/cc/local/eth.json',
        bnb: './deployments/cc/local/bnb.json'
      });
    }

    if (keccak256(abi.encodePacked(ENV)) == keccak256(abi.encodePacked("testnet"))) {
      return CrossChainAddressFiles({
        eth: './deployments/cc/testnet/sep.json',
        bnb: './deployments/cc/testnet/bnb_test.json'
      });
    }

    return CrossChainAddressFiles({
      eth: './deployments/cc/mainnet/eth.json',
      bnb: './deployments/cc/mainnet/bnb.json'
    });
  }

  function _decodeJson(string memory path, Vm vm) internal view returns (Addresses memory) {
    string memory persistedJson = vm.readFile(path);

    Addresses memory addresses = Addresses({
      proxyAdmin: abi.decode(persistedJson.parseRaw('.proxyAdmin'), (address)),
      proxyFactory: abi.decode(persistedJson.parseRaw('.proxyFactory'), (address)),
      owner: abi.decode(persistedJson.parseRaw('.owner'), (address)),
      guardian: abi.decode(persistedJson.parseRaw('.guardian'), (address)),
      crossChainController: abi.decode(persistedJson.parseRaw('.crossChainController'), (address)),
      crossChainControllerImpl: abi.decode(
        persistedJson.parseRaw('.crossChainControllerImpl'),
        (address)
      ),
      ccipAdapter: abi.decode(persistedJson.parseRaw('.ccipAdapter'), (address)),
      chainId: abi.decode(persistedJson.parseRaw('.chainId'), (uint256)),
      lzAdapter: abi.decode(persistedJson.parseRaw('.lzAdapter'), (address)),
      hlAdapter: abi.decode(persistedJson.parseRaw('.hlAdapter'), (address)),
      mockDestination: abi.decode(persistedJson.parseRaw('.mockDestination'), (address)),
      wormholeAdapter: abi.decode(persistedJson.parseRaw('.wormholeAdapter'), (address)),
      executor: abi.decode(persistedJson.parseRaw('.executor'), (address))
    });

    return addresses;
  }

  function setUp() virtual public {
    CrossChainAddressFiles memory files = _getDeploymentFiles();
    crossChainAddresses.eth = _decodeJson(files.eth, vm);
    crossChainAddresses.bnb = _decodeJson(files.bnb, vm);

    ethFork = vm.createFork('ethereum-local');
    bnbFork = vm.createFork('binance-local');
  }

  /**
    * @notice Send a message with the specified destination and message via a.DI
    * @param _crossChainController The address of the cross chain controller
    * @param _destination The destination address of the message
    * @param _destinationChainId The destination chain ID of the message
    * @param _message The message of the envelope
    */
  function _sendCrossChainTransactionAsDao(
    address _crossChainController,
    address _destination,
    uint256 _destinationChainId,
    bytes memory _message
  ) internal returns (ExtendedTransaction memory) {
    ICrossChainController crossChainController = ICrossChainController(_crossChainController);

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

    return extendedTx;
  }

  function _receiveDaoCrossChainMessage(
    address _crossChainController,
    address[] memory adapters,
    ExtendedTransaction memory originalExtendedTx
  ) internal {
    ICrossChainController targetCrossChainController = ICrossChainController(_crossChainController);

    vm.recordLogs();

    for (uint256 i = 0; i < adapters.length; i++) {
      vm.prank(adapters[i], ZERO_ADDRESS);
      targetCrossChainController.receiveCrossChainMessage(
        originalExtendedTx.transactionEncoded,
        originalExtendedTx.envelope.originChainId
      );
    }
  }
}
