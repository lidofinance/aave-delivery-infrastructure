// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Script.sol';

import '../BaseScript.sol';

interface AragonTokenInterface {
  function forward(bytes calldata evmScript) external;
}

interface AragonVotingInterface {
  function votesLength() external view returns (uint256);

  function vote(uint256 _voteId, bool _supports, bool _executesIfDecided) external;

  function executeVote(uint256 _voteId) external;
}

abstract contract VoteAgentChangeScript is BaseScript {

  bool immutable IS_FORK = false;

  uint32 immutable DEFAULT_EXECUTOR_ID = 1;

  address immutable FAKE_DAO_VOTING = 0x124208720f804A9ded96F0CD532018614b8aE28d;
  address immutable FAKE_DAO_TOKEN = 0xdAc681011f846Af90AEbd11d0C9Cc6BCa70Dd636;

  struct Action {
    address _to;
    bytes _calldata;
  }

  function TRANSACTION_NETWORK() public pure virtual override returns (uint256);

  function _execute(DeployerHelpers.Addresses memory addresses) internal override {
    _initiateNewVote(addresses);

    uint256 voteId = AragonVotingInterface(FAKE_DAO_VOTING).votesLength() - 1;

    AragonVotingInterface(FAKE_DAO_VOTING).vote(voteId, true, false);

    // @dev checking locally that voting works
    if (IS_FORK) {
      vm.warp(block.timestamp + 1260); // 21 minutes to pass the voting period

      AragonVotingInterface(FAKE_DAO_VOTING).executeVote(voteId);
    }
  }

  function _agentExecute(address _agent, address _to, uint256 _value, bytes memory data) internal pure returns (Action memory) {
    bytes memory _calldata = abi.encodeWithSignature('execute(address,uint256,bytes)', _to, _value, data);

    return Action(_agent, _calldata);
  }

  function _encodeCallScript(Action[] memory _actions) internal pure returns (bytes memory) {
    bytes memory _script = abi.encodePacked(uint32(DEFAULT_EXECUTOR_ID));
    for (uint256 i = 0; i < _actions.length; i++) {
      address _to = _actions[i]._to;
      bytes memory _calldata = _actions[i]._calldata;

      _script = bytes.concat(
        _script,
        abi.encodePacked(address(_to)),
        abi.encodePacked(uint32(_calldata.length)),
        _calldata
      );
    }

    return _script;
  }

  function _initiateNewVote(DeployerHelpers.Addresses memory addresses) internal {
    bytes memory _voteCallData = abi.encodeWithSignature(
      'newVote(bytes,string,bool,bool)',
      _buildOwnershipTransferMotion(addresses),
      'Vote to transfer ownership to the new DAO',
      false,
      false
    );

    Action[] memory actions = new Action[](1);
    actions[0]._to = FAKE_DAO_VOTING;
    actions[0]._calldata = _voteCallData;

    bytes memory evmScript = _encodeCallScript(actions);

    AragonTokenInterface(FAKE_DAO_TOKEN).forward(evmScript);
  }

  function _buildOwnershipTransferMotion(DeployerHelpers.Addresses memory addresses) internal view returns (bytes memory) {
    DeployerHelpers.Addresses memory bnbAddresses = _getAddresses(ChainIds.BNB);

    Action[] memory actions = new Action[](5);

    actions[0] = _agentExecute(
      Constants.LIDO_DAO_AGENT_FAKE,
      addresses.crossChainController,
      0,
      abi.encodeWithSignature('forwardMessage(uint256,address,uint256,bytes)',
        ChainIds.BNB,
        bnbAddresses.executorMock,
        1000000,
        _buildBinanceOwnershipTransferMotion(bnbAddresses)
      )
    );

    address[] memory approveSenders = new address[](1);
    approveSenders[0] = Constants.LIDO_DAO_AGENT;

    actions[1] = _agentExecute(
      Constants.LIDO_DAO_AGENT_FAKE,
      addresses.crossChainController,
      0,
      abi.encodeWithSignature('approveSenders(address[])', approveSenders)
    );

    address[] memory removeSenders = new address[](1);
    removeSenders[0] = Constants.LIDO_DAO_AGENT_FAKE;

    actions[2] = _agentExecute(
      Constants.LIDO_DAO_AGENT_FAKE,
      addresses.crossChainController,
      0,
      abi.encodeWithSignature('removeSenders(address[])', removeSenders)
    );

    actions[3] = _agentExecute(
      Constants.LIDO_DAO_AGENT_FAKE,
      addresses.crossChainController,
      0,
      abi.encodeWithSignature('transferOwnership(address)', Constants.LIDO_DAO_AGENT)
    );

    actions[4] = _agentExecute(
      Constants.LIDO_DAO_AGENT_FAKE,
      addresses.proxyAdmin,
      0,
      abi.encodeWithSignature('transferOwnership(address)', Constants.LIDO_DAO_AGENT)
    );

    return _encodeCallScript(actions);
  }

  function _buildBinanceOwnershipTransferMotion(DeployerHelpers.Addresses memory bnbAddresses) internal pure returns (bytes memory) {
    address[] memory addresses = new address[](2);
    addresses[0] = bnbAddresses.crossChainController;
    addresses[1] = bnbAddresses.proxyAdmin;

    uint256[] memory values = new uint256[](2);
    values[0] = uint256(0);
    values[1] = uint256(0);

    string[] memory signatures = new string[](2);
    signatures[0] = 'transferOwnership(address)';
    signatures[1] = 'transferOwnership(address)';

    bytes[] memory calldatas = new bytes[](2);
    calldatas[0] = abi.encode(bnbAddresses.executorProd);
    calldatas[1] = abi.encode(bnbAddresses.executorProd);

    bool[] memory withDelegatecalls = new bool[](2);
    withDelegatecalls[0] = false;
    withDelegatecalls[1] = false;

    return abi.encode(addresses, values, signatures, calldatas, withDelegatecalls);
  }
}

contract Ethereum is VoteAgentChangeScript {
  function TRANSACTION_NETWORK() public pure override returns (uint256) {
    return ChainIds.ETHEREUM;
  }
}
