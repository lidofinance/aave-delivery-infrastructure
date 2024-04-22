// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AxelarAdapter} from '../../src/contracts/adapters/axelar/AxelarAdapter.sol';
import {AxelarAdapterTestnet} from '../contract_extensions/AxelarAdapter.sol';
import '../BaseScript.sol';
import './BaseAdapterScript.sol';

abstract contract BaseAxelarAdapter is BaseAdapterScript {
  function AXELAR_GATEWAY() public view virtual returns (address);

  function isTestNet() public view virtual returns (bool);

  function AXELAR_GAS_SERVICE() public view returns (address) {
    if (isTestNet()) {
      return 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6;
    } else {
      return 0x2d5d7d31F671F86C782533cc367F14109a082712;
    }
  }

  function _deployAdapter(
    DeployerHelpers.Addresses memory addresses,
    IBaseAdapter.TrustedRemotesConfig[] memory trustedRemotes
  ) internal override {
    address axelarAdapter;
    if (isTestNet()) {
      axelarAdapter = address(new AxelarAdapterTestnet(AXELAR_GATEWAY(), AXELAR_GAS_SERVICE()));
    } else {
      axelarAdapter = address(new AxelarAdapter(AXELAR_GATEWAY(), AXELAR_GAS_SERVICE()));
    }
    addresses.axelarAdapter = axelarAdapter;
  }
}

contract Ethereum is BaseAxelarAdapter {
  function AXELAR_GATEWAY() public pure override returns (address) {
    return 0x4F4495243837681061C4743b74B3eEdf548D56A5;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function REMOTE_NETWORKS() public pure override returns (uint256[] memory) {
    uint256[] memory remoteNetworks = new uint256[](0);

    return remoteNetworks;
  }

  function isTestNet() public pure override returns (bool) {
    return false;
  }
}

contract Ethereum_testnet is BaseAxelarAdapter {
  function AXELAR_GATEWAY() public pure override returns (address) {
    return 0xe432150cce91c13a887f7D836923d5597adD8E31;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }

  function REMOTE_NETWORKS() public pure override returns (uint256[] memory) {
    uint256[] memory remoteNetworks = new uint256[](0);

    return remoteNetworks;
  }

  function isTestNet() public pure override returns (bool) {
    return true;
  }
}

contract Binance is BaseAxelarAdapter {
  function AXELAR_GATEWAY() public pure override returns (address) {
    return 0x304acf330bbE08d1e512eefaa92F6a57871fD895;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }

  function REMOTE_NETWORKS() public pure override returns (uint256[] memory) {
    uint256[] memory remoteNetworks = new uint256[](1);
    remoteNetworks[0] = ChainIds.ETHEREUM;

    return remoteNetworks;
  }

  function isTestNet() public pure override returns (bool) {
    return false;
  }
}

contract Binance_testnet is BaseAxelarAdapter {
  function AXELAR_GATEWAY() public pure override returns (address) {
    return 0x304acf330bbE08d1e512eefaa92F6a57871fD895;
  }

  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.BNB;
  }

  function REMOTE_NETWORKS() public pure override returns (uint256[] memory) {
    uint256[] memory remoteNetworks = new uint256[](1);
    remoteNetworks[0] = ChainIds.ETHEREUM;

    return remoteNetworks;
  }

  function isTestNet() public pure override returns (bool) {
    return true;
  }
}
