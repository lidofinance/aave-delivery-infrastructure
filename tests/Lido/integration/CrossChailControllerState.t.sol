pragma solidity ^0.8.19;

import 'forge-std/console2.sol';

import {BaseIntegrationTest} from "./BaseIntegrationTest.sol";

import {ICrossChainController} from "../../../src/contracts/interfaces/ICrossChainController.sol";
import {Ownable} from "solidity-utils/contracts/oz-common/Ownable.sol";

contract CrossChainControllerStateTest is BaseIntegrationTest {

  function test_CrossChainControllerState() public {
    Ownable ownableCC = Ownable(address(crossChainAddresses.eth.crossChainController));

    console2.log("CrossChainController address: %s", address(crossChainAddresses.eth.crossChainController));
    console2.log("CrossChainController owner: %s", ownableCC.owner());

    assertEq(ownableCC.owner(), address(0));

    Ownable ownableCCImpl = Ownable(address(crossChainAddresses.eth.crossChainControllerImpl));

    console2.log("CrossChainControllerImpl address: %s", address(crossChainAddresses.eth.crossChainControllerImpl));
    console2.log("CrossChainControllerImpl owner: %s", ownableCCImpl.owner());

    assertEq(ownableCCImpl.owner(), 0x000000000000000000000000000000000000dEaD);
  }
}
