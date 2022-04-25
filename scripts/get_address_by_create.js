const hre = require("hardhat");

async function main() {

    const factoryCt = await hre.ethers.getContractFactory("DelegatorFactory");
    const factory = await factoryCt.deploy();

    await factory.deployed();
    let sender = "0x9a6DD2f7CEb71788de691844d16b6b6852f07aA3";
    let nonce = 61;
    console.log(factory.getAddressByCreate(sender, nonce));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });