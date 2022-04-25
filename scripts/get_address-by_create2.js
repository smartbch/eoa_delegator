const hre = require("hardhat");
const {ethers} = require("ethers");
const {bnToHex} = require("hardhat/internal/hardhat-network/provider/utils/bnToHex");

async function main() {
    const delegatorCt = await hre.ethers.getContractFactory("EOADelegator");
    const factoryCt = await hre.ethers.getContractFactory("DelegatorFactory");
    const factory = await factoryCt.deploy();
    await factory.deployed();

    const from = "0x9a6DD2f7CEb71788de691844d16b6b6852f07aA3"; //todo: update this to delegatorFactory in mainnet
    let address;
    for (let i = 0; ; i++) {
        //console.log(bnToHex(i));
        address = calAddressByCreate2(from, delegatorCt.bytecode, bnToHex(i));
        if (i < 10) {
            let addressFromContract = await factory.getAddress(from, i);
            if (addressFromContract !== address) {
                console.log("address created not same between solidity and node.js")
                return
            }
        }
        //console.log(address);
        if (address.toLowerCase().startsWith("0xe0a00")) {
            console.log("salt:", i, "address:", address);
            break
        }
        if (i % 100000 === 0) {
            console.log("now reach:", i);
        }
    }
}

function calAddressByCreate2(fromAddr, deployCode, salt /*hex string*/) {
    const deployCodeHash = ethers.utils.keccak256(deployCode)
    return ethers.utils.getCreate2Address(fromAddr, ethers.utils.hexZeroPad(salt, 32), deployCodeHash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });