//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract MockEOA is Proxy {
    address eoa_delegator;
    uint vault256;
    uint tokenA256;
    uint tokenB256;
    constructor(address _eoa_delegator, address _tokenA, address _tokenB, address _vault){
        eoa_delegator = _eoa_delegator;
        vault256 = uint(uint160(_vault)) << 96;
        tokenA256 = uint(uint160(_tokenA)) << 96;
        tokenB256 = uint(uint160(_tokenB)) << 96;
    }
    function _implementation() internal view override returns (address) {
        return eoa_delegator;
    }

    function _delegate(address implementation) internal override {
        uint amount = 1000 * 10 ** 18;
        uint _tokenA = tokenA256;
        uint _tokenB = tokenB256;
        uint _vault = vault256;
        uint _tokenAmount = 2 << 248;
        assembly {
            calldatacopy(0, 0, calldatasize())
        // uint contractAddr256;
        // uint tokenAddr256;
        // uint amount;
        // ...
        // uint8 tokenNum;
            mstore(calldatasize(), _vault)
            mstore(add(calldatasize(), 20), _tokenA)
            mstore(add(calldatasize(), 40), amount)
            mstore(add(calldatasize(), 72), _tokenB)
            mstore(add(calldatasize(), 92), amount)
            mstore(add(calldatasize(), 124), _tokenAmount)

            let result := delegatecall(gas(), implementation, 0, add(calldatasize(), 125), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                //log0(0, returndatasize())
                return (0, returndatasize())
            }
        }
    }
}

contract MockEOANotBuildCallData is Proxy {
    address eoa_delegator;
    constructor(address _eoa_delegator){
        eoa_delegator = _eoa_delegator;
    }
    function _implementation() internal view override returns (address) {
        return eoa_delegator;
    }
}

contract Token is ERC20 {
    constructor()ERC20("test", "TST") {
        super._mint(msg.sender, 10000 * 10 ** 18);
    }
}

contract Vault {
    IERC20 tokenA;
    IERC20 tokenB;
    string constant public LONG_STRING = "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789";
    constructor(address _tokenA, address _tokenB){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function work() public returns (string memory) {
        console.log("msg.sender:%s", msg.sender);
        tokenA.transferFrom(msg.sender, address(this), 100 * 10 ** 18);
        tokenB.transferFrom(msg.sender, address(this), 100 * 10 ** 18);
        return LONG_STRING;
    }
}
