// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AxelarAdapter} from '../../src/contracts/adapters/axelar/AxelarAdapter.sol';
import {ChainIds} from '../../src/contracts/libs/ChainIds.sol';
import {Errors} from '../../src/contracts/libs/Errors.sol';
import {IAxelarGMPExecutable} from '../../src/contracts/adapters/axelar/interfaces/IAxelarGMPExecutable.sol';
import {IAxelarGasService} from '../../src/contracts/adapters/axelar/interfaces/IAxelarGasService.sol';
import {IInterchainGasEstimation} from '../../src/contracts/adapters/axelar/interfaces/IInterchainGasEstimation.sol';
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
    assertEq(axelarAdapter.axelarToInfraChainId('Ethereum'), ChainIds.ETHEREUM);
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
    assertEq(axelarAdapter.infraToAxelarChainId(ChainIds.ETHEREUM), 'Ethereum');
    assertEq(axelarAdapter.infraToAxelarChainId(ChainIds.BNB), 'binance');
  }

  function testReceiveMsg(
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

  function testReceiveMsgWhenSourceNotTrusted(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId,
    address sourceAddress
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
    vm.assume(originForwarder != address(0) && sourceAddress != originForwarder);

    bytes memory payload = abi.encode('test msg');
    string memory axelarChainId = axelarAdapter.infraToAxelarChainId(originChainId);

    vm.mockCall(
      axelarGateway,
      abi.encodeWithSelector(IAxelarGMPGateway.validateContractCall.selector),
      abi.encode(true)
    );

    vm.expectRevert(bytes(Errors.REMOTE_NOT_TRUSTED));

    AxelarGMPExecutable(axelarAdapter).execute(
      keccak256(abi.encode('commandId')),
      axelarChainId,
      AddressToString.toString(sourceAddress),
      payload
    );
  }

  function testForwardPayload(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId,
    uint256 gasLimit,
    address receiver
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
    vm.assume(originChainId == ChainIds.ETHEREUM);
    vm.assume(originForwarder != address(0));
    vm.assume(gasLimit > 0);

    bytes memory payload = abi.encode('test msg');

    vm.expectCall(
      axelarGateway,
      0,
      abi.encodeWithSelector(
        IAxelarGMPGateway.callContract.selector,
        axelarAdapter.infraToAxelarChainId(ChainIds.BNB),
        AddressToString.toString(receiver),
        payload
      )
    );

    _testForwardMsg(axelarGateway, axelarGasService, receiver, ChainIds.BNB, gasLimit, payload);
  }

  function testForwardPayloadUnsupportedChain(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId,
    uint256 gasLimit,
    address receiver
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
    vm.assume(originChainId == ChainIds.ETHEREUM);
    vm.assume(originForwarder != address(0));
    vm.assume(gasLimit > 0);

    bytes memory payload = abi.encode('test msg');

    vm.expectRevert(bytes(Errors.DESTINATION_CHAIN_ID_NOT_SUPPORTED));

    _testForwardMsg(axelarGateway, axelarGasService, receiver, 123456789, gasLimit, payload);
  }

  function testForwardPayloadWhenInvalidReceiver(
    address crossChainController,
    address axelarGateway,
    address axelarGasService,
    address originForwarder,
    uint256 originChainId,
    uint256 gasLimit
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
    vm.assume(originChainId == ChainIds.ETHEREUM);
    vm.assume(originForwarder != address(0));
    vm.assume(gasLimit > 0);

    bytes memory payload = abi.encode('test msg');

    vm.expectRevert(bytes(Errors.RECEIVER_NOT_SET));

    _testForwardMsg(axelarGateway, axelarGasService, address(0), ChainIds.BNB, gasLimit, payload);
  }

  function _testForwardMsg(
    address axelarGateway,
    address axelarGasService,
    address receiver,
    uint256 dstChain,
    uint256 gasLimit,
    bytes memory payload
  ) internal returns (address, uint256) {
    vm.mockCall(
      axelarGasService,
      abi.encodeWithSelector(IInterchainGasEstimation.estimateGasFee.selector),
      abi.encode(0.01 ether)
    );

    vm.mockCall(
      axelarGasService,
      0.01 ether,
      abi.encodeWithSelector(IAxelarGasService.payNativeGasForContractCall.selector),
      abi.encode()
    );

    vm.mockCall(
      axelarGateway,
      abi.encodeWithSelector(IAxelarGMPGateway.callContract.selector),
      abi.encode()
    );

    (address gateway, uint nonce) = axelarAdapter.forwardMessage(
      receiver,
      gasLimit,
      dstChain,
      payload
    );

    return (gateway, nonce);
  }
}
