pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';
import 'forge-std/StdJson.sol';

import {BaseTest} from "../../BaseTest.sol";

contract BaseIntegrationTest is BaseTest {
  using stdJson for string;

  string ENV = vm.envString('ENV');

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
    address polAdapter;
    address proxyAdmin;
    address proxyFactory;
    address wormholeAdapter;
  }

  struct CrossChainAddresses {
    Addresses eth;
    Addresses pol;
    Addresses bnb;
  }

  struct CrossChainAddressFiles {
    string eth;
    string pol;
    string bnb;
  }

  CrossChainAddresses internal crossChainAddresses;

  function _getDeploymentFiles() internal view returns (CrossChainAddressFiles memory) {
    if (keccak256(abi.encodePacked(ENV)) == keccak256(abi.encodePacked("local"))) {
      return CrossChainAddressFiles({
        eth: './deployments/cc/local/eth.json',
        pol: './deployments/cc/local/pol.json',
        bnb: './deployments/cc/local/bnb.json'
      });
    }

    if (keccak256(abi.encodePacked(ENV)) == keccak256(abi.encodePacked("testnet"))) {
      return CrossChainAddressFiles({
        eth: './deployments/cc/testnet/sep.json',
        pol: './deployments/cc/testnet/mum.json',
        bnb: './deployments/cc/testnet/bnb_test.json'
      });
    }

    return CrossChainAddressFiles({
      eth: './deployments/cc/mainnet/eth.json',
      pol: './deployments/cc/mainnet/pol.json',
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
      polAdapter: abi.decode(persistedJson.parseRaw('.polAdapter'), (address)),
      mockDestination: abi.decode(persistedJson.parseRaw('.mockDestination'), (address)),
      wormholeAdapter: abi.decode(persistedJson.parseRaw('.wormholeAdapter'), (address))
    });

    return addresses;
  }

  function setUp() public {
    CrossChainAddressFiles memory files = _getDeploymentFiles();
    crossChainAddresses.eth = _decodeJson(files.eth, vm);
    crossChainAddresses.pol = _decodeJson(files.pol, vm);
    crossChainAddresses.bnb = _decodeJson(files.bnb, vm);
  }
}
