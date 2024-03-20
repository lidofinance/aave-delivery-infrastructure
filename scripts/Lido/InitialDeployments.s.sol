// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TransparentProxyFactory} from 'solidity-utils/contracts/transparent-proxy/TransparentProxyFactory.sol';

import {LidoAddressBook} from './LidoAddressBook.sol';

import './BaseScript.sol';

abstract contract BaseInitialDeployment is BaseScript {
  function OWNER() public virtual returns (address) {
    return address(msg.sender); // as first owner we set deployer, this way its easier to configure
  }

  function GUARDIAN() public virtual returns (address) {
    return address(0);
  }

  function TRANSPARENT_PROXY_FACTORY() public pure virtual returns (address) {
    return address(0);
  }

  function PROXY_ADMIN() public virtual returns (address) {
    return address(0);
  }

  function _execute(DeployerHelpers.Addresses memory addresses) internal override {
    addresses.proxyFactory = TRANSPARENT_PROXY_FACTORY() == address(0)
      ? address(new TransparentProxyFactory())
      : TRANSPARENT_PROXY_FACTORY();
    addresses.proxyAdmin = PROXY_ADMIN() == address(0)
      ? TransparentProxyFactory(addresses.proxyFactory).createDeterministicProxyAdmin(
        OWNER(),
        Constants.ADMIN_SALT
      )
      : PROXY_ADMIN();
    addresses.chainId = TRANSACTION_NETWORK();
    addresses.owner = OWNER();
    addresses.guardian = GUARDIAN();
  }
}

contract Ethereum is BaseInitialDeployment {
  function TRANSPARENT_PROXY_FACTORY() public pure override returns (address) {
    return LidoAddressBook.TRANSPARENT_PROXY_FACTORY_ETHEREUM;
  }

  function PROXY_ADMIN() public pure override returns (address) {
    return LidoAddressBook.PROXY_ADMIN_ETHEREUM;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}

contract Polygon is BaseInitialDeployment {
  function TRANSPARENT_PROXY_FACTORY() public pure override returns (address) {
    return LidoAddressBook.TRANSPARENT_PROXY_FACTORY_POLYGON;
  }

  function PROXY_ADMIN() public pure override returns (address) {
    return LidoAddressBook.PROXY_ADMIN_POLYGON;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.POLYGON;
  }
}

contract Binance is BaseInitialDeployment {
  function TRANSPARENT_PROXY_FACTORY() public pure override returns (address) {
    return LidoAddressBook.TRANSPARENT_PROXY_FACTORY_BINANCE;
  }

  function PROXY_ADMIN() public pure override returns (address) {
    return LidoAddressBook.PROXY_ADMIN_BINANCE;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }
}

contract Ethereum_testnet is BaseInitialDeployment {
  function TRANSPARENT_PROXY_FACTORY() public pure override returns (address) {
    return LidoAddressBook.TRANSPARENT_PROXY_FACTORY_ETHEREUM_TESTNET;
  }

  function PROXY_ADMIN() public pure override returns (address) {
    return LidoAddressBook.PROXY_ADMIN_ETHEREUM_TESTNET;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }
}

contract Polygon_testnet is BaseInitialDeployment {
  function TRANSPARENT_PROXY_FACTORY() public pure override returns (address) {
    return LidoAddressBook.TRANSPARENT_PROXY_FACTORY_POLYGON_TESTNET;
  }

  function PROXY_ADMIN() public pure override returns (address) {
    return LidoAddressBook.PROXY_ADMIN_POLYGON_TESTNET;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.POLYGON_MUMBAI;
  }
}

contract Binance_testnet is BaseInitialDeployment {
  function TRANSPARENT_PROXY_FACTORY() public pure override returns (address) {
    return LidoAddressBook.TRANSPARENT_PROXY_FACTORY_BINANCE_TESTNET;
  }

  function PROXY_ADMIN() public pure override returns (address) {
    return LidoAddressBook.PROXY_ADMIN_BINANCE_TESTNET;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.BNB_TESTNET;
  }
}
