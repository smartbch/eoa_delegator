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
        assembly {
            contractAddr256 := calldataload(inputSize)
            inputSize := add(inputSize, 20)
        }
        address contractAddr = address(bytes20(uint160(contractAddr256 >> 96)));

        // fetch three variables from the end of calldata
        address[] memory tokens = new address[](tokenNums);
        for (uint i = 0; i < tokenNums; i++) {
            uint tokenAddr256;
            uint amount;
            assembly {
                tokenAddr256 := calldataload(inputSize)
                inputSize := add(inputSize, 20)
                amount := calldataload(inputSize)
                inputSize := add(inputSize, 32)
            }
            // Approve an SEP20 token to the target contract
            tokens[i] = address(bytes20(uint160(tokenAddr256 >> 96)));
            (bool success, bytes memory data) = tokens[i].call(abi.encodeWithSelector(APPROVE, contractAddr, amount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "approve failed");
        }
        // call target contract
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, inputSize)
            let result := call(gas(), contractAddr, callvalue(), ptr, inputSize, 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
        }
        for (uint j = 0; j < tokenNums; j++) {
            // Revoke the approved allowance
            (bool success, bytes memory data) = tokens[j].call(abi.encodeWithSelector(APPROVE, contractAddr, 0));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "revoke approve failed");
        }
        // return on success
        assembly {
            return (0, returndatasize())
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
    address public deployer;
    constructor(address _deployer){
        deployer = _deployer;
    }
    event NewContractCreated(address indexed addr);

    function getAddress(uint tokenNums, uint salt) public view returns (address) {
        bytes memory bytecode = type(eoa_delegator).creationCode;
        bytes32 codeHash = keccak256(abi.encodePacked(bytecode, abi.encode(tokenNums)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), deployer, bytes32(salt), codeHash));
        return address(uint160(uint(hash)));
    }
}