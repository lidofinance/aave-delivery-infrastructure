// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AxelarAdapter} from '../../src/contracts/adapters/axelar/AxelarAdapter.sol';
import {ChainIds} from '../../src/contracts/libs/ChainIds.sol';
import {Errors} from '../../src/contracts/libs/Errors.sol';
import {IAxelarGMPExecutable} from '../../src/contracts/adapters/axelar/interfaces/IAxelarGMPExecutable.sol';
import {AddressToString} from '../../src/contracts/adapters/axelar/libs/AddressString.sol';
import {IAxelarGMPGateway} from '../../src/contracts/adapters/axelar/interfaces/IAxelarGMPGateway.sol';
import {AxelarGMPExecutable} from '../../src/contracts/adapters/axelar/libs/AxelarGMPExecutable.sol';
import {ICrossChainReceiver} from '../../src/contracts/interfaces/ICrossChainReceiver.sol';
import {IBaseAdapter} from '../../src/contracts/adapters/IBaseAdapter.sol';
import {BaseAdapter} from '../../src/contracts/adapters/BaseAdapter.sol';
import {BaseAdapterTest} from './BaseAdapterTest.sol';
import 'forge-std/Test.sol';

contract AxelarAdapterTest is BaseAdapterTest {
  AxelarAdapter axelarAdapter;

  modifier setAxelarAdapter(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId
  ) {
    _assumeSafeAddress(crossChainController);
    _assumeSafeAddress(axelarGateway);
    _assumeSafeAddress(axelarGasService);
    _assumeSafeAddress(originForwarder);
    vm.assume(originChainId > 0);

    IBaseAdapter.TrustedRemotesConfig memory originConfig = IBaseAdapter.TrustedRemotesConfig({
      originForwarder: originForwarder,
      originChainId: originChainId
    });
    IBaseAdapter.TrustedRemotesConfig[]
      memory originConfigs = new IBaseAdapter.TrustedRemotesConfig[](1);
    originConfigs[0] = originConfig;

    axelarAdapter = new AxelarAdapter(
      crossChainController,
      axelarGateway,
      axelarGasService,
      crossChainController,
      originConfigs
    );
    _;
  }

  function setUp() public {}

  function testWrongAxelarGateway(
    address crossChainController,
    address originForwarder,
    uint256 originChainId
  ) public {
    vm.assume(crossChainController != address(0));
    vm.assume(originForwarder != address(0));
    vm.assume(originChainId == 1);

    IBaseAdapter.TrustedRemotesConfig memory originConfig = IBaseAdapter.TrustedRemotesConfig({
      originForwarder: originForwarder,
      originChainId: originChainId
    });
    IBaseAdapter.TrustedRemotesConfig[]
      memory originConfigs = new IBaseAdapter.TrustedRemotesConfig[](1);
    originConfigs[0] = originConfig;

    vm.expectRevert(IAxelarGMPExecutable.InvalidAddress.selector);
    new AxelarAdapter(
      crossChainController,
      address(0),
      address(1),
      crossChainController,
      originConfigs
    );
  }

  function testInit(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId
  )
    public
    setAxelarAdapter(
      crossChainController,
      axelarGateway,
      axelarGasService,
      originForwarder,
      originChainId
    )
  {
    assertEq(
      keccak256(abi.encode(BaseAdapter(axelarAdapter).adapterName())),
      keccak256(abi.encode('Axelar adapter'))
    );
    assertEq(originForwarder, axelarAdapter.getTrustedRemoteByChainId(originChainId));
    assertEq(address(AxelarGMPExecutable(axelarAdapter).gateway()), axelarGateway);
  }

  function testGetInfraChainFromAxelarChain(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId
  )
    public
    setAxelarAdapter(
      crossChainController,
      axelarGateway,
      axelarGasService,
      originForwarder,
      originChainId
    )
  {
    assertEq(axelarAdapter.axelarToInfraChainId('ethereum'), ChainIds.ETHEREUM);
    assertEq(axelarAdapter.axelarToInfraChainId('binance'), ChainIds.BNB);
  }

  function testGetAxelarChainFromInfraChain(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId
  )
    public
    setAxelarAdapter(
      crossChainController,
      axelarGateway,
      axelarGasService,
      originForwarder,
      originChainId
    )
  {
    assertEq(axelarAdapter.infraToAxelarChainId(ChainIds.ETHEREUM), 'ethereum');
    assertEq(axelarAdapter.infraToAxelarChainId(ChainIds.BNB), 'binance');
  }

  function testAxelarMsgReceive(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId
  )
    public
    setAxelarAdapter(
      crossChainController,
      axelarGateway,
      axelarGasService,
      originForwarder,
      originChainId
    )
  {
    vm.assume(originChainId == 1);
    vm.assume(originForwarder != address(0));

    bytes memory payload = abi.encode('test msg');
    string memory axelarChainId = axelarAdapter.infraToAxelarChainId(originChainId);

    vm.mockCall(
      axelarGateway,
      abi.encodeWithSelector(IAxelarGMPGateway.validateContractCall.selector),
      abi.encode(true)
    );

    vm.mockCall(
      crossChainController,
      abi.encodeWithSelector(ICrossChainReceiver.receiveCrossChainMessage.selector),
      abi.encode()
    );

    vm.expectCall(
      crossChainController,
      0,
      abi.encodeWithSelector(
        ICrossChainReceiver.receiveCrossChainMessage.selector,
        payload,
        originChainId
      )
    );

    AxelarGMPExecutable(axelarAdapter).execute(
      keccak256(abi.encode('commandId')),
      axelarChainId,
      AddressToString.toString(originForwarder),
      payload
    );
  }
}
