// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract eoa_delegator {
    bytes4 internal constant APPROVE = bytes4(keccak256(bytes("approve(address,uint256)")));
    uint immutable tokenNums;
    uint immutable ExtraBytes;

    constructor(uint _tokenNums) {
        tokenNums = _tokenNums;
        ExtraBytes = (32 + 20) * _tokenNums + 20;
    }

    function _delegate() internal {
        // we will use the beginning of the calldata to call the target contract
        uint inputSize;
        uint extraBytes = ExtraBytes;
        assembly {
            inputSize := sub(calldatasize(), extraBytes)
        }
        uint contractAddr256;
		uint argPtr = inputSize;
        assembly {
            contractAddr256 := calldataload(argPtr)
            argPtr := add(argPtr, 20)
        }
        address contractAddr = address(bytes20(uint160(contractAddr256 >> 96)));

        address[] memory tokens = new address[](tokenNums);
        for (uint i = 0; i < tokenNums; i++) {
            // fetch two variables from the end of calldata
            uint tokenAddr256;
            uint amount;
            assembly {
                tokenAddr256 := calldataload(argPtr)
                argPtr := add(argPtr, 20)
                amount := calldataload(argPtr)
                argPtr := add(argPtr, 32)
            }
            // Approve an SEP20 token to the target contract
            tokens[i] = address(bytes20(uint160(tokenAddr256 >> 96)));
            (bool success, bytes memory data) = tokens[i].call(abi.encodeWithSelector(APPROVE, contractAddr, amount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "approve failed");
        }
        uint callRetPtr;
        uint retSize;
        // call target contract
        assembly {
            callRetPtr := mload(0x40) // store the "free memory pointer"
            calldatacopy(callRetPtr, 0, inputSize)
            let result := call(gas(), contractAddr, callvalue(), callRetPtr, inputSize, 0, 0)
            retSize := returndatasize()
            let ptr := add(callRetPtr, retSize)
            returndatacopy(callRetPtr, 0, retSize)
            if eq(result, 0) {
                revert(callRetPtr, retSize)
            }
            mstore(0x40, ptr)
        }
        for (uint j = 0; j < tokenNums; j++) {
            // Revoke the approved allowance
            (bool success, bytes memory data) = tokens[j].call(abi.encodeWithSelector(APPROVE, contractAddr, 0));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "revoke approve failed");
        }
        // return on success
        assembly {
            return (callRetPtr, retSize)
        }
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }
}

contract DelegatorFactory {
    event NewContractCreated(uint indexed tokenNums, address indexed addr);

    function getAddress(uint _tokenNums, uint _salt, address _deployer) public view returns (address) {
        bytes memory bytecode = type(eoa_delegator).creationCode;
        bytes32 codeHash = keccak256(abi.encodePacked(bytecode, abi.encode(_tokenNums)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), _deployer, bytes32(_salt), codeHash));
        return address(uint160(uint(hash)));
    }

    function getAddressByCreate(address _sender, uint _nonce) public view returns (address){
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _sender, bytes1(_nonce))))));
    }

    function create(uint _salt, uint _tokenNums) external {
        address delegator = address(new eoa_delegator{salt : _salt}(_tokenNums));
        emit NewContractCreated(_tokenNums, proxy);
    }
}