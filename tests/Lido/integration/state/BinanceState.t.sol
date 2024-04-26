pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';

import {ChainIds} from "../../../../src/contracts/libs/ChainIds.sol";

import {BaseStateTest} from "./BaseStateTest.sol";

contract CrossChainControllerStateTest is BaseStateTest {

  address public proxyAdmin;
  address public cccAddress;
  address public cccImplAddress;

  address public BINANCE_LIDO_DAO_AGENT;

  function setUp() override public {
    super.setUp();

    vm.selectFork(bnbFork);

    proxyAdmin = address(crossChainAddresses.bnb.proxyAdmin);
    cccAddress = address(crossChainAddresses.bnb.crossChainController);
    cccImplAddress = address(crossChainAddresses.bnb.crossChainControllerImpl);

    BINANCE_LIDO_DAO_AGENT = crossChainAddresses.bnb.executor;

    console2.log("Binance DAO Agent (CrossChainExecutor): %s", BINANCE_LIDO_DAO_AGENT);
  }

  function test_CorrectFork() public {
    _test_fork(bnbFork, "Binance");
  }

  function test_ProxyAdminState() public {
    _test_proxy_admin(proxyAdmin, cccAddress, cccImplAddress, BINANCE_LIDO_DAO_AGENT);
  }

  function test_CrossChainControllerState() public {
    _test_ccc_owners(cccAddress, BINANCE_LIDO_DAO_AGENT);
    _test_ccc_funds(cccAddress, 0);
  }

  function test_CrossChainController_ForwarderAdaptersState() public {
    AdaptersConfig[] memory ccfAdaptersLists = new AdaptersConfig[](2);

    ccfAdaptersLists[0].chainId = ChainIds.ETHEREUM;
    ccfAdaptersLists[0].adapters = new AdapterLink[](0);

    ccfAdaptersLists[1].chainId = ChainIds.POLYGON;
    ccfAdaptersLists[1].adapters = new AdapterLink[](0);

    _test_ccf_adapters(
      cccAddress,
      ccfAdaptersLists
    );
  }

  function test_CrossChainController_ReceiverAdaptersState() public {
    AdaptersConfig[] memory ccrAdaptersLists = new AdaptersConfig[](2);

    ccrAdaptersLists[0].chainId = ChainIds.ETHEREUM;
    ccrAdaptersLists[0].adapters = new AdapterLink[](4);

    ccrAdaptersLists[0].adapters[0].localAdapter = address(crossChainAddresses.bnb.ccipAdapter);
    ccrAdaptersLists[0].adapters[0].destinationAdapter = address(crossChainAddresses.eth.ccipAdapter);
    ccrAdaptersLists[0].adapters[1].localAdapter = address(crossChainAddresses.bnb.lzAdapter);
    ccrAdaptersLists[0].adapters[1].destinationAdapter = address(crossChainAddresses.eth.lzAdapter);
    ccrAdaptersLists[0].adapters[2].localAdapter = address(crossChainAddresses.bnb.hlAdapter);
    ccrAdaptersLists[0].adapters[2].destinationAdapter = address(crossChainAddresses.eth.hlAdapter);
    ccrAdaptersLists[0].adapters[3].localAdapter = address(crossChainAddresses.bnb.wormholeAdapter);
    ccrAdaptersLists[0].adapters[3].destinationAdapter = address(crossChainAddresses.eth.wormholeAdapter);

    ccrAdaptersLists[1].chainId = ChainIds.POLYGON;
    ccrAdaptersLists[1].adapters = new AdapterLink[](0);

    _test_ccr_adapters(
      cccAddress,
      ccrAdaptersLists
    );
  }

  function test_CrossChainControllerImplState() public {
    _test_ccc_impl(cccImplAddress);
  }
}
