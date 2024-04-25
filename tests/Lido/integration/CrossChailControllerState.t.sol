pragma solidity ^0.8.19;

import 'forge-std/console2.sol';

import {BaseIntegrationTest} from "./BaseIntegrationTest.sol";

import {Ownable} from "solidity-utils/contracts/oz-common/Ownable.sol";
import {OwnableWithGuardian} from "solidity-utils/contracts/access-control/OwnableWithGuardian.sol";

contract CrossChainControllerStateTest is BaseIntegrationTest {

  function test_CrossChainController_EthereumState() public {
    vm.selectFork(ethFork);

    address proxyAdmin = address(crossChainAddresses.eth.proxyAdmin);
    address proxyAdminOwner = Ownable(proxyAdmin).owner();

    address ccc = address(crossChainAddresses.eth.crossChainController);
    address cccOwner = Ownable(ccc).owner();
    address cccGuardian = OwnableWithGuardian(ccc).guardian();

    address cccImplAddress = address(crossChainAddresses.eth.crossChainControllerImpl);
    address cccImplOwner = Ownable(cccImplAddress).owner();
    address cccImplGuardian = OwnableWithGuardian(cccImplAddress).guardian();

    console2.log("ProxyAdmin address: %s", proxyAdmin);
    console2.log("ProxyAdmin owner: %s", proxyAdminOwner);

    assertEq(proxyAdminOwner, LIDO_DAO, "ProxyAdmin owner should be LIDO_DAO");

    console2.log("CrossChainController address: %s", ccc);
    console2.log("CrossChainController owner: %s", cccOwner);
    console2.log("CrossChainController guardian: %s", cccGuardian);

    assertEq(cccOwner, LIDO_DAO, "CrossChainController owner should be LIDO_DAO");
    assertEq(cccGuardian, ZERO, "CrossChainController guardian should be ZERO");

    console2.log("CrossChainControllerImpl address: %s", cccImplAddress);
    console2.log("CrossChainControllerImpl owner: %s", cccImplOwner);
    console2.log("CrossChainControllerImpl guardian: %s", cccImplGuardian);

    assertEq(cccImplOwner, DEAD, "CrossChainControllerImpl owner should be DEAD");
    assertEq(cccImplGuardian, ZERO, "CrossChainControllerImpl guardian should be ZERO");
  }

  function test_CrossChainController_PolygonState() public {
    vm.selectFork(polFork);

    address proxyAdmin = address(crossChainAddresses.pol.proxyAdmin);
    address proxyAdminOwner = Ownable(proxyAdmin).owner();

    address ccc = address(crossChainAddresses.pol.crossChainController);
    address cccOwner = Ownable(ccc).owner();
    address cccGuardian = OwnableWithGuardian(ccc).guardian();

    address cccImplAddress = address(crossChainAddresses.pol.crossChainControllerImpl);
    address cccImplOwner = Ownable(cccImplAddress).owner();
    address cccImplGuardian = OwnableWithGuardian(cccImplAddress).guardian();

    address EXECUTOR = crossChainAddresses.pol.executor;

    console2.log("CrossChainExecutor on Polygon: %s", EXECUTOR);
    console2.log("ProxyAdmin address: %s", proxyAdmin);
    console2.log("ProxyAdmin owner: %s", proxyAdminOwner);

    assertEq(proxyAdminOwner, EXECUTOR, "ProxyAdmin owner should be CrossChainExecutor on Polygon");

    console2.log("CrossChainController address: %s", ccc);
    console2.log("CrossChainController owner: %s", cccOwner);
    console2.log("CrossChainController guardian: %s", cccGuardian);

    assertEq(cccOwner, EXECUTOR, "CrossChainController owner should be CrossChainExecutor on Polygon");
    assertEq(cccGuardian, ZERO, "CrossChainController guardian should be ZERO");

    console2.log("CrossChainControllerImpl address: %s", cccImplAddress);
    console2.log("CrossChainControllerImpl owner: %s", cccImplOwner);
    console2.log("CrossChainControllerImpl guardian: %s", cccImplGuardian);

    assertEq(cccImplOwner, DEAD, "CrossChainControllerImpl owner should be DEAD");
    assertEq(cccImplGuardian, ZERO, "CrossChainControllerImpl guardian should be ZERO");
  }

  function test_CrossChainController_BinanceState() public {
    vm.selectFork(bnbFork);

    address proxyAdmin = address(crossChainAddresses.bnb.proxyAdmin);
    address proxyAdminOwner = Ownable(proxyAdmin).owner();

    address ccc = address(crossChainAddresses.bnb.crossChainController);
    address cccOwner = Ownable(ccc).owner();
    address cccGuardian = OwnableWithGuardian(ccc).guardian();

    address cccImplAddress = address(crossChainAddresses.bnb.crossChainControllerImpl);
    address cccImplOwner = Ownable(cccImplAddress).owner();
    address cccImplGuardian = OwnableWithGuardian(cccImplAddress).guardian();

    address EXECUTOR = crossChainAddresses.bnb.executor;

    console2.log("CrossChainExecutor on Binance: %s", EXECUTOR);
    console2.log("ProxyAdmin address: %s", proxyAdmin);
    console2.log("ProxyAdmin owner: %s", proxyAdminOwner);

    assertEq(proxyAdminOwner, EXECUTOR, "ProxyAdmin owner should be CrossChainExecutor on Binance");

    console2.log("CrossChainController address: %s", ccc);
    console2.log("CrossChainController owner: %s", cccOwner);
    console2.log("CrossChainController guardian: %s", cccGuardian);

    assertEq(cccOwner, EXECUTOR, "CrossChainController owner should be CrossChainExecutor on Binance");
    assertEq(cccGuardian, ZERO, "CrossChainController guardian should be ZERO");

    console2.log("CrossChainControllerImpl address: %s", cccImplAddress);
    console2.log("CrossChainControllerImpl owner: %s", cccImplOwner);
    console2.log("CrossChainControllerImpl guardian: %s", cccImplGuardian);

    assertEq(cccImplOwner, DEAD, "CrossChainControllerImpl owner should be DEAD");
    assertEq(cccImplGuardian, ZERO, "CrossChainControllerImpl guardian should be ZERO");
  }
}
