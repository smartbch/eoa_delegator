// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract eoa_delegator_1 {
    bytes4 internal constant APPROVE = bytes4(keccak256(bytes("approve(address,uint256)")));
    uint constant ExtraBytes = 32+20+20;

    function _delegate() internal {
        // we will use the beginning of the calldata to call the target contract
	uint inputSize = 72;
        assembly {
	    inputSize := sub(calldatasize(), ExtraBytes)
	}
	bytes memory callData = new bytes(inputSize);
        assembly {
            calldatacopy(callData, 0, inputSize)
	}

	// fetch three variables from the end of calldata
        uint amount;
        uint tokenAddr256;
        uint contractAddr256;
        assembly {
	    amount := calldataload(inputSize)
	    inputSize := add(inputSize, 32)
	    tokenAddr256 := calldataload(inputSize)
	    inputSize := add(inputSize, 20)
	    contractAddr256 := calldataload(inputSize)
	}

	// Approve an SEP20 token to the target contract
        address tokenAddr = address(bytes20(uint160(tokenAddr256>>96)));
        address contractAddr = address(bytes20(uint160(contractAddr256>>96)));
        (bool success, bytes memory data) = tokenAddr.call(abi.encodeWithSelector(APPROVE, contractAddr, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));

	// call target contract
	bytes memory ret;
        (success, ret) = contractAddr.call(callData);
        assembly {
            if eq(success, 0) { revert(ret, returndatasize()) }
        }

	// Revoke the approved allowance
        (success, data) = tokenAddr.call(abi.encodeWithSelector(APPROVE, contractAddr, 0));
        require(success && (data.length == 0 || abi.decode(data, (bool))));

	// return on success
	uint retSize = ret.length;
        assembly {
            return(ret, retSize)
        }
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

}
