pragma solidity ^0.8.19;

import 'forge-std/console2.sol';
import 'forge-std/Vm.sol';

import {ChainIds} from "../../../src/contracts/libs/ChainIds.sol";

import {BaseStateTest} from "./BaseStateTest.sol";

contract EthereumStateTest is BaseStateTest {

  address public proxyAdmin;
  address public cccAddress;
  address public cccImplAddress;

  function setUp() override public {
    super.setUp();

    vm.selectFork(ethFork);

    proxyAdmin = address(crossChainAddresses.eth.proxyAdmin);
    cccAddress = address(crossChainAddresses.eth.crossChainController);
    cccImplAddress = address(crossChainAddresses.eth.crossChainControllerImpl);

    console2.log("Ethereum DAO Agent: %s", LIDO_DAO_AGENT);
  }

  function test_CorrectFork() public {
    _test_fork(ethFork, "Ethereum");
  }

  function test_ProxyAdminState() public {
    _test_proxy_admin(proxyAdmin, cccAddress, cccImplAddress, LIDO_DAO_AGENT);
  }

  function test_CrossChainControllerState() public {
    _test_ccc_owners(cccAddress, LIDO_DAO_AGENT);
    _test_ccc_funds(cccAddress, 5e17); // 0.5 ETH
  }

  function test_CrossChainController_ForwarderAdaptersState() public {
    AdaptersConfig[] memory ccfAdaptersLists = new AdaptersConfig[](2);

    ccfAdaptersLists[0].chainId = ChainIds.POLYGON;
    ccfAdaptersLists[0].adapters = new AdapterLink[](0);
//    ccfAdaptersLists[0].adapters = new AdapterLink[](4);
//    ccfAdaptersLists[0].adapters[0].localAdapter = address(crossChainAddresses.eth.ccipAdapter);
//    ccfAdaptersLists[0].adapters[0].destinationAdapter = address(crossChainAddresses.pol.ccipAdapter);
//    ccfAdaptersLists[0].adapters[1].localAdapter = address(crossChainAddresses.eth.lzAdapter);
//    ccfAdaptersLists[0].adapters[1].destinationAdapter = address(crossChainAddresses.pol.lzAdapter);
//    ccfAdaptersLists[0].adapters[2].localAdapter = address(crossChainAddresses.eth.hlAdapter);
//    ccfAdaptersLists[0].adapters[2].destinationAdapter = address(crossChainAddresses.pol.hlAdapter);
//    ccfAdaptersLists[0].adapters[3].localAdapter = address(crossChainAddresses.eth.polAdapter);
//    ccfAdaptersLists[0].adapters[3].destinationAdapter = address(crossChainAddresses.pol.polAdapter);

    ccfAdaptersLists[1].chainId = ChainIds.BNB;
    ccfAdaptersLists[1].adapters = new AdapterLink[](4);
    ccfAdaptersLists[1].adapters[0].localAdapter = address(crossChainAddresses.eth.ccipAdapter);
    ccfAdaptersLists[1].adapters[0].destinationAdapter = address(crossChainAddresses.bnb.ccipAdapter);
    ccfAdaptersLists[1].adapters[1].localAdapter = address(crossChainAddresses.eth.lzAdapter);
    ccfAdaptersLists[1].adapters[1].destinationAdapter = address(crossChainAddresses.bnb.lzAdapter);
    ccfAdaptersLists[1].adapters[2].localAdapter = address(crossChainAddresses.eth.hlAdapter);
    ccfAdaptersLists[1].adapters[2].destinationAdapter = address(crossChainAddresses.bnb.hlAdapter);
    ccfAdaptersLists[1].adapters[3].localAdapter = address(crossChainAddresses.eth.wormholeAdapter);
    ccfAdaptersLists[1].adapters[3].destinationAdapter = address(crossChainAddresses.bnb.wormholeAdapter);

    _test_ccf_adapters(
      cccAddress,
      ccfAdaptersLists
    );
  }

  function test_CrossChainController_ReceiverAdaptersState() public {
    AdaptersConfig[] memory ccrAdaptersLists = new AdaptersConfig[](1);

    ccrAdaptersLists[0].chainId = ChainIds.BNB;
    ccrAdaptersLists[0].adapters = new AdapterLink[](0);

//    ccrAdaptersLists[1].chainId = ChainIds.POLYGON;
//    ccrAdaptersLists[1].adapters = new AdapterLink[](0);

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

    trustedRemotes[0].chainId = ChainIds.BNB;
    trustedRemotes[0].remoteCrossChainControllerAddress = ZERO_ADDRESS;

//    trustedRemotes[1].chainId = ChainIds.POLYGON;
//    trustedRemotes[1].remoteCrossChainControllerAddress = ZERO_ADDRESS;

    _test_adapter(
      address(crossChainAddresses.eth.ccipAdapter),
      'CCIP adapter',
      cccAddress,
      trustedRemotes
    );
  }

  function test_lzAdapter() public {
    TrustedRemotesConfig[] memory trustedRemotes = new TrustedRemotesConfig[](1);

    trustedRemotes[0].chainId = ChainIds.BNB;
    trustedRemotes[0].remoteCrossChainControllerAddress = ZERO_ADDRESS;

//    trustedRemotes[1].chainId = ChainIds.POLYGON;
//    trustedRemotes[1].remoteCrossChainControllerAddress = ZERO_ADDRESS;

    _test_adapter(
      address(crossChainAddresses.eth.lzAdapter),
      'LayerZero adapter',
      cccAddress,
      trustedRemotes
    );
  }

  function test_hlAdapter() public {
    TrustedRemotesConfig[] memory trustedRemotes = new TrustedRemotesConfig[](1);

    trustedRemotes[0].chainId = ChainIds.BNB;
    trustedRemotes[0].remoteCrossChainControllerAddress = ZERO_ADDRESS;

//    trustedRemotes[1].chainId = ChainIds.POLYGON;
//    trustedRemotes[1].remoteCrossChainControllerAddress = ZERO_ADDRESS;

    _test_adapter(
      address(crossChainAddresses.eth.hlAdapter),
      'Hyperlane adapter',
      cccAddress,
      trustedRemotes
    );
  }

//  function test_polAdapter() public {
//    TrustedRemotesConfig[] memory trustedRemotes = new TrustedRemotesConfig[](2);
//
//    trustedRemotes[0].chainId = ChainIds.POLYGON;
//    trustedRemotes[0].remoteCrossChainControllerAddress = ZERO_ADDRESS;
//
//    trustedRemotes[1].chainId = ChainIds.BNB;
//    trustedRemotes[1].remoteCrossChainControllerAddress = ZERO_ADDRESS; // no connection to BNB
//
//    _test_adapter(
//      address(crossChainAddresses.eth.polAdapter),
//      'Polygon native adapter',
//      cccAddress,
//      trustedRemotes
//    );
//  }

  function test_wormholeAdapter() public {
    TrustedRemotesConfig[] memory trustedRemotes = new TrustedRemotesConfig[](1);

    trustedRemotes[0].chainId = ChainIds.BNB;
    trustedRemotes[0].remoteCrossChainControllerAddress = ZERO_ADDRESS;

//    trustedRemotes[1].chainId = ChainIds.BNB;
//    trustedRemotes[1].remoteCrossChainControllerAddress = ZERO_ADDRESS;

    _test_adapter(
      address(crossChainAddresses.eth.wormholeAdapter),
      'Wormhole adapter',
      cccAddress,
      trustedRemotes
    );
  }
}
