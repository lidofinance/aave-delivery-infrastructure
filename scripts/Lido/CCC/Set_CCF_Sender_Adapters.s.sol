// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICrossChainForwarder} from '../../../src/contracts/interfaces/ICrossChainForwarder.sol';

import '../BaseScript.sol';

abstract contract BaseCCFSenderAdapters is BaseScript {
  function getBridgeAdaptersToEnable(
    DeployerHelpers.Addresses memory addresses
  ) public view virtual returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory);

  function _execute(DeployerHelpers.Addresses memory addresses) internal override {
    ICrossChainForwarder(addresses.crossChainController).enableBridgeAdapters(
      getBridgeAdaptersToEnable(addresses)
    );
  }
}

contract Ethereum is BaseCCFSenderAdapters {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }

  function getBridgeAdaptersToEnable(
    DeployerHelpers.Addresses memory addresses
  ) public view override returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory) {
    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[]
    memory bridgeAdaptersToEnable = new ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[](4);

    // binance path
    DeployerHelpers.Addresses memory addressesBNB = _getAddresses(ChainIds.BNB);
    bridgeAdaptersToEnable[0] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: addresses.ccipAdapter,
      destinationBridgeAdapter: addressesBNB.ccipAdapter,
      destinationChainId: addressesBNB.chainId
    });
    bridgeAdaptersToEnable[1] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: addresses.lzAdapter,
      destinationBridgeAdapter: addressesBNB.lzAdapter,
      destinationChainId: addressesBNB.chainId
    });
    bridgeAdaptersToEnable[2] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: addresses.hlAdapter,
      destinationBridgeAdapter: addressesBNB.hlAdapter,
      destinationChainId: addressesBNB.chainId
    });
    bridgeAdaptersToEnable[3] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: addresses.wormholeAdapter,
      destinationBridgeAdapter: addressesBNB.wormholeAdapter,
      destinationChainId: addressesBNB.chainId
    });

//    // polygon path
//    DeployerHelpers.Addresses memory addressesPolygon = _getAddresses(ChainIds.POLYGON);
//    bridgeAdaptersToEnable[4] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
//      currentChainBridgeAdapter: addresses.ccipAdapter,
//      destinationBridgeAdapter: addressesPolygon.ccipAdapter,
//      destinationChainId: addressesPolygon.chainId
//    });
//    bridgeAdaptersToEnable[5] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
//      currentChainBridgeAdapter: addresses.lzAdapter,
//      destinationBridgeAdapter: addressesPolygon.lzAdapter,
//      destinationChainId: addressesPolygon.chainId
//    });
//    bridgeAdaptersToEnable[6] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
//      currentChainBridgeAdapter: addresses.hlAdapter,
//      destinationBridgeAdapter: addressesPolygon.hlAdapter,
//      destinationChainId: addressesPolygon.chainId
//    });
//    bridgeAdaptersToEnable[7] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
//      currentChainBridgeAdapter: addresses.polAdapter,
//      destinationBridgeAdapter: addressesPolygon.polAdapter,
//      destinationChainId: addressesPolygon.chainId
//    });

    return bridgeAdaptersToEnable;
  }
}

contract Ethereum_testnet is BaseCCFSenderAdapters {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return TestNetChainIds.ETHEREUM_SEPOLIA;
  }

  function getBridgeAdaptersToEnable(
    DeployerHelpers.Addresses memory addresses
  ) public view override returns (ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[] memory) {
    ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[]
      memory bridgeAdaptersToEnable = new ICrossChainForwarder.ForwarderBridgeAdapterConfigInput[](4);

    // binance path
    DeployerHelpers.Addresses memory addressesBNB = _getAddresses(TestNetChainIds.BNB_TESTNET);
    bridgeAdaptersToEnable[0] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: addresses.ccipAdapter,
      destinationBridgeAdapter: addressesBNB.ccipAdapter,
      destinationChainId: addressesBNB.chainId
    });
    bridgeAdaptersToEnable[1] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: addresses.lzAdapter,
      destinationBridgeAdapter: addressesBNB.lzAdapter,
      destinationChainId: addressesBNB.chainId
    });
    bridgeAdaptersToEnable[2] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: addresses.hlAdapter,
      destinationBridgeAdapter: addressesBNB.hlAdapter,
      destinationChainId: addressesBNB.chainId
    });
    bridgeAdaptersToEnable[3] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
      currentChainBridgeAdapter: addresses.wormholeAdapter,
      destinationBridgeAdapter: addressesBNB.wormholeAdapter,
      destinationChainId: addressesBNB.chainId
    });

    // polygon path
//    DeployerHelpers.Addresses memory addressesPolygon = _getAddresses(TestNetChainIds.POLYGON_MUMBAI);
//    bridgeAdaptersToEnable[4] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
//      currentChainBridgeAdapter: addresses.ccipAdapter,
//      destinationBridgeAdapter: addressesPolygon.ccipAdapter,
//      destinationChainId: addressesPolygon.chainId
//    });
//    bridgeAdaptersToEnable[5] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
//      currentChainBridgeAdapter: addresses.lzAdapter,
//      destinationBridgeAdapter: addressesPolygon.lzAdapter,
//      destinationChainId: addressesPolygon.chainId
//    });
//    bridgeAdaptersToEnable[6] = ICrossChainForwarder.ForwarderBridgeAdapterConfigInput({
//      currentChainBridgeAdapter: addresses.hlAdapter,
//      destinationBridgeAdapter: addressesPolygon.hlAdapter,
//      destinationChainId: addressesPolygon.chainId
//    });

    return bridgeAdaptersToEnable;
  }
}

contract Ethereum_local is Ethereum {
  function isLocalFork() public pure override returns (bool) {
    return true;
  }
}
