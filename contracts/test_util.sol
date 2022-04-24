//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract mock_eoa is Proxy {
    address eoa_delegator;
    uint vault256;
    uint token256;
    constructor(address _eoa_delegator, address _token, address _vault){
        eoa_delegator = _eoa_delegator;
        vault256 = uint(uint160(_vault)) << 96;
        token256 = uint(uint160(_token)) << 96;
    }
    function _implementation() internal view override returns (address) {
        return eoa_delegator;
    }

    function _delegate(address implementation) internal override {
        uint amount = 1000 * 10 ** 18;
        uint _token = token256;
        uint _vault = vault256;
        assembly {
            calldatacopy(0, 0, calldatasize())
            // uint amount;
            // uint tokenAddr256;
            // uint contractAddr256;
            mstore(calldatasize(), amount)
            mstore(add(calldatasize(), 32), _token)
            mstore(add(calldatasize(), 52), _vault)
            let result := delegatecall(gas(), implementation, 0, add(calldatasize(), 72), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }
}

contract token is ERC20 {
    constructor()ERC20("test", "TST") {
        super._mint(msg.sender, 10000 * 10 ** 18);
    }
}

contract vault {
    IERC20 usd;

    constructor(address _token){
        usd = IERC20(_token);
    }

    function work() public {
        console.log("msg.sender:%s", msg.sender);
        usd.transferFrom(msg.sender, address(this), 100 * 10 ** 18);
    }
}
