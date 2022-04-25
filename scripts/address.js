const hre = require("hardhat");

async function main() {

    const factoryCt = await hre.ethers.getContractFactory("DelegatorFactory");
    const factory = await factoryCt.deploy("0x9a6DD2f7CEb71788de691844d16b6b6852f07aA3");

    await factory.deployed();
    console.log(await factory.deployer());
    let address;
    for (let i = 20000; i < 1000000; i++) {
        address = await factory.getAddress(1, i);
        //console.log(address.toLowerCase());
        if (address.toLowerCase().startsWith("0xeoa01")) {
            console.log("salt:", i, "address:", address);
            break
        }
        if (i % 10000 === 0) {
            console.log("now reach:", i);
        }
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });