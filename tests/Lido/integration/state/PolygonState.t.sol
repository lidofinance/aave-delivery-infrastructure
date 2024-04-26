pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';

import {ChainIds} from "../../../../src/contracts/libs/ChainIds.sol";

import {BaseStateTest} from "./BaseStateTest.sol";

contract CrossChainControllerStateTest is BaseStateTest {

  address public proxyAdmin;
  address public cccAddress;
  address public cccImplAddress;

  address public POLYGON_LIDO_DAO_AGENT;

  function setUp() override public {
    super.setUp();

    vm.selectFork(polFork);

    proxyAdmin = address(crossChainAddresses.pol.proxyAdmin);
    cccAddress = address(crossChainAddresses.pol.crossChainController);
    cccImplAddress = address(crossChainAddresses.pol.crossChainControllerImpl);

    POLYGON_LIDO_DAO_AGENT = crossChainAddresses.pol.executor;

    console2.log("Polygon PoS DAO Agent (CrossChainExecutor): %s", POLYGON_LIDO_DAO_AGENT);
  }

  function test_CorrectFork() public {
    _test_fork(polFork, "Polygon PoS");
  }

  function test_ProxyAdminState() public {
    _test_proxy_admin(proxyAdmin, cccAddress, cccImplAddress, POLYGON_LIDO_DAO_AGENT);
  }

  function test_CrossChainControllerState() public {
    _test_ccc_owners(cccAddress, POLYGON_LIDO_DAO_AGENT);
    _test_ccc_funds(cccAddress, 0);
  }

  function test_CrossChainController_ForwarderAdaptersState() public {
    AdaptersConfig[] memory ccfAdaptersLists = new AdaptersConfig[](2);

    ccfAdaptersLists[0].chainId = ChainIds.ETHEREUM;
    ccfAdaptersLists[0].adapters = new AdapterLink[](0);

    ccfAdaptersLists[1].chainId = ChainIds.BNB;
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

    ccrAdaptersLists[0].adapters[0].localAdapter = address(crossChainAddresses.pol.ccipAdapter);
    ccrAdaptersLists[0].adapters[0].destinationAdapter = address(crossChainAddresses.eth.ccipAdapter);
    ccrAdaptersLists[0].adapters[1].localAdapter = address(crossChainAddresses.pol.lzAdapter);
    ccrAdaptersLists[0].adapters[1].destinationAdapter = address(crossChainAddresses.eth.lzAdapter);
    ccrAdaptersLists[0].adapters[2].localAdapter = address(crossChainAddresses.pol.hlAdapter);
    ccrAdaptersLists[0].adapters[2].destinationAdapter = address(crossChainAddresses.eth.hlAdapter);
    ccrAdaptersLists[0].adapters[3].localAdapter = address(crossChainAddresses.pol.polAdapter);
    ccrAdaptersLists[0].adapters[3].destinationAdapter = address(crossChainAddresses.eth.polAdapter);

    ccrAdaptersLists[1].chainId = ChainIds.BNB;
    ccrAdaptersLists[1].adapters = new AdapterLink[](0);

    _test_ccr_adapters(
      cccAddress,
      ccrAdaptersLists
    );
  }

  function test_CrossChainControllerImplState() public {
    _test_ccc_impl(cccImplAddress);
  }

  function test_ccipAdapter() public {
    TrustedRemotesConfig[] memory trustedRemotes = new TrustedRemotesConfig[](1);

    trustedRemotes[0].chainId = ChainIds.ETHEREUM;
    trustedRemotes[0].remoteCrossChainControllerAddress = address(crossChainAddresses.eth.crossChainController);

    _test_adapter(
      address(crossChainAddresses.pol.ccipAdapter),
      'CCIP adapter',
      cccAddress,
      trustedRemotes
    );
  }

  function test_lzAdapter() public {
    TrustedRemotesConfig[] memory trustedRemotes = new TrustedRemotesConfig[](1);

    trustedRemotes[0].chainId = ChainIds.ETHEREUM;
    trustedRemotes[0].remoteCrossChainControllerAddress = address(crossChainAddresses.eth.crossChainController);

    _test_adapter(
      address(crossChainAddresses.pol.lzAdapter),
      'LayerZero adapter',
      cccAddress,
      trustedRemotes
    );
  }

  function test_hlAdapter() public {
    TrustedRemotesConfig[] memory trustedRemotes = new TrustedRemotesConfig[](1);

    trustedRemotes[0].chainId = ChainIds.ETHEREUM;
    trustedRemotes[0].remoteCrossChainControllerAddress = address(crossChainAddresses.eth.crossChainController);

    _test_adapter(
      address(crossChainAddresses.pol.hlAdapter),
      'Hyperlane adapter',
      cccAddress,
      trustedRemotes
    );
  }

  function test_polAdapter() public {
    TrustedRemotesConfig[] memory trustedRemotes = new TrustedRemotesConfig[](1);

    trustedRemotes[0].chainId = ChainIds.ETHEREUM;
    trustedRemotes[0].remoteCrossChainControllerAddress = address(crossChainAddresses.eth.crossChainController);

    _test_adapter(
      address(crossChainAddresses.pol.polAdapter),
      'Polygon native adapter',
      cccAddress,
      trustedRemotes
    );
  }

}
