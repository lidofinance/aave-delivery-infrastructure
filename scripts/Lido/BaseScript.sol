// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';
import 'forge-std/Vm.sol';
import 'forge-std/StdJson.sol';

import {TestNetChainIds} from '../contract_extensions/TestNetChainIds.sol';
import {ChainIds} from '../../src/contracts/libs/ChainIds.sol';

  struct Network {
    string path;
    string name;
  }

library DeployerHelpers {
  using stdJson for string;

  struct Addresses {
    address ccipAdapter;
    uint256 chainId;
    address clEmergencyOracle;
    address crossChainController;
    address crossChainControllerImpl;
    address emergencyRegistry;
    address guardian;
    address hlAdapter;
    address lzAdapter;
    address mockDestination;
    address polAdapter;
    address proxyAdmin;
    address proxyFactory;
    address wormholeAdapter;
    address executor;
  }

  function getPathByChainId(uint256 chainId, bool isLocalFork) internal pure returns (string memory) {
    string memory prefix = isLocalFork ? './deployments/cc/local/' : 'deployments/cc/mainnet/';
    if (chainId == ChainIds.ETHEREUM) {
      return string.concat(prefix, 'eth.json');
    } else if (chainId == ChainIds.POLYGON) {
      return string.concat(prefix, 'pol.json');
    } else if (chainId == ChainIds.BNB) {
      return string.concat(prefix, 'bnb.json');
    }

    if (chainId == TestNetChainIds.ETHEREUM_SEPOLIA) {
      return './deployments/cc/testnet/sep.json';
    } else if (chainId == TestNetChainIds.POLYGON_MUMBAI) {
      return './deployments/cc/testnet/mum.json';
    } else if (chainId == TestNetChainIds.BNB_TESTNET) {
      return './deployments/cc/testnet/bnb_test.json';
    } else {
      revert('chain id is not supported');
    }
  }

  function decodeJson(string memory path, Vm vm) internal view returns (Addresses memory) {
    string memory persistedJson = vm.readFile(path);

    Addresses memory addresses = Addresses({
      proxyAdmin: abi.decode(persistedJson.parseRaw('.proxyAdmin'), (address)),
      proxyFactory: abi.decode(persistedJson.parseRaw('.proxyFactory'), (address)),
      guardian: abi.decode(persistedJson.parseRaw('.guardian'), (address)),
      clEmergencyOracle: abi.decode(persistedJson.parseRaw('.clEmergencyOracle'), (address)),
      crossChainController: abi.decode(persistedJson.parseRaw('.crossChainController'), (address)),
      crossChainControllerImpl: abi.decode(
        persistedJson.parseRaw('.crossChainControllerImpl'),
        (address)
      ),
      ccipAdapter: abi.decode(persistedJson.parseRaw('.ccipAdapter'), (address)),
      chainId: abi.decode(persistedJson.parseRaw('.chainId'), (uint256)),
      emergencyRegistry: abi.decode(persistedJson.parseRaw('.emergencyRegistry'), (address)),
      hlAdapter: abi.decode(persistedJson.parseRaw('.hlAdapter'), (address)),
      lzAdapter: abi.decode(persistedJson.parseRaw('.lzAdapter'), (address)),
      polAdapter: abi.decode(persistedJson.parseRaw('.polAdapter'), (address)),
      wormholeAdapter: abi.decode(persistedJson.parseRaw('.wormholeAdapter'), (address)),
      mockDestination: abi.decode(persistedJson.parseRaw('.mockDestination'), (address)),
      executor: abi.decode(persistedJson.parseRaw('.executor'), (address))
    });

    return addresses;
  }

  function encodeJson(string memory path, Addresses memory addresses, Vm vm) internal {
    string memory json = 'addresses';
    json.serialize('ccipAdapter', addresses.ccipAdapter);
    json.serialize('chainId', addresses.chainId);
    json.serialize('clEmergencyOracle', addresses.clEmergencyOracle);
    json.serialize('crossChainController', addresses.crossChainController);
    json.serialize('crossChainControllerImpl', addresses.crossChainControllerImpl);
    json.serialize('emergencyRegistry', addresses.emergencyRegistry);
    json.serialize('guardian', addresses.guardian);
    json.serialize('hlAdapter', addresses.hlAdapter);
    json.serialize('lzAdapter', addresses.lzAdapter);
    json.serialize('mockDestination', addresses.mockDestination);
    json.serialize('polAdapter', addresses.polAdapter);
    json.serialize('wormholeAdapter', addresses.wormholeAdapter);
    json.serialize('proxyAdmin', addresses.proxyAdmin);
    json.serialize('executor', addresses.executor);
    json = json.serialize('proxyFactory', addresses.proxyFactory);
    vm.writeJson(json, path);
  }
}

library Constants {
  // https://docs.lido.fi/deployed-contracts/sepolia#dao-contracts - Aragon Agent
  address public constant LIDO_DAO_AGENT = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c;
  address public constant LIDO_DAO_AGENT_FAKE = 0x184d39300f2fA4419d04998e9C58Cb5De586d879;
  address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address public constant ZERO = 0x0000000000000000000000000000000000000000;
}

abstract contract BaseScript is Script {
  function TRANSACTION_NETWORK() public view virtual returns (uint256);

  function isLocalFork() public view virtual returns (bool) {
    return false;
  }

  function getAddresses(
    uint256 networkId
  ) external view returns (DeployerHelpers.Addresses memory) {
    return DeployerHelpers.decodeJson(
      DeployerHelpers.getPathByChainId(networkId, isLocalFork()),
      vm
    );
  }

  function _getAddresses(
    uint256 networkId
  ) internal view returns (DeployerHelpers.Addresses memory) {
    try this.getAddresses(networkId) returns (DeployerHelpers.Addresses memory addresses) {
      return addresses;
    } catch (bytes memory) {
      DeployerHelpers.Addresses memory empty;
      return empty;
    }
  }

  function _setAddresses(uint256 networkId, DeployerHelpers.Addresses memory addresses) internal {
    DeployerHelpers.encodeJson(DeployerHelpers.getPathByChainId(networkId, isLocalFork()), addresses, vm);
  }

  function _execute(DeployerHelpers.Addresses memory addresses) internal virtual;

  function run() public {
    vm.startBroadcast();
    // ----------------- Persist addresses -----------------------------------------------------------------------------
    DeployerHelpers.Addresses memory addresses = _getAddresses(TRANSACTION_NETWORK());
    // -----------------------------------------------------------------------------------------------------------------
    _execute(addresses);
    // ----------------- Persist addresses -----------------------------------------------------------------------------
    _setAddresses(TRANSACTION_NETWORK(), addresses);
    // -----------------------------------------------------------------------------------------------------------------
    vm.stopBroadcast();
  }
}
