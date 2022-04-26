const fs = require('fs');

const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("delegator", function () {

    let owner;
    let vaultCt;
    let delegator, eoa, vault;
    let usd, abc;

    before(async function () {
            [owner] = await ethers.getSigners();
            const token = await ethers.getContractFactory("Token");
            usd = await token.deploy();
            abc = await token.deploy();
            const delegatorCt = await ethers.getContractFactory("EOADelegator");
            delegator = await delegatorCt.deploy();
            vaultCt = await ethers.getContractFactory("Vault");
            vault = await vaultCt.deploy(usd.address, abc.address);
            const mock_eoa = await ethers.getContractFactory("MockEOA");
            eoa = await mock_eoa.deploy(delegator.address, usd.address, abc.address, vault.address);
        }
    )

    it("call contract failed", async function () {
        let contract = vaultCt.attach(eoa.address);
        expect(await usd.balanceOf(eoa.address)).to.equal(0);
        await expect(contract.work()).to.be.revertedWith("ERC20: transfer amount exceeds balance");
        expect(await usd.balanceOf(vault.address)).to.equal(0n);
        expect(await usd.allowance(eoa.address, vault.address)).to.equal(0n);
    });

    it("two token approve", async function () {
        await usd.transfer(eoa.address, 2000n * 10n ** 18n);
        expect(await usd.balanceOf(eoa.address)).to.equal(2000n * 10n ** 18n);
        await abc.transfer(eoa.address, 2000n * 10n ** 18n);
        expect(await abc.balanceOf(eoa.address)).to.equal(2000n * 10n ** 18n);
        console.log("eoa address:", eoa.address);
        let contract = vaultCt.attach(eoa.address);
        const tx = await contract.work();
        const receipt = await tx.wait();
        expect(await usd.balanceOf(vault.address)).to.equal(100n * 10n ** 18n);
        expect(await usd.allowance(eoa.address, vault.address)).to.equal(0n);
        expect(await abc.balanceOf(vault.address)).to.equal(100n * 10n ** 18n);
        expect(await abc.allowance(eoa.address, vault.address)).to.equal(0n);

        const res = await contract.callStatic.work()
        expect(res).to.equal(await vault.LONG_STRING());
    });

    it("test factory", async function () {
        const factoryCt = await ethers.getContractFactory("DelegatorFactory");
        const factory = await factoryCt.deploy();
        const tx = await factory.create(1);
        const receipt = await tx.wait();
        expect(receipt.logs[0].topics[1]).to.equal(ethers.utils.hexZeroPad(await factory.getAddress(factory.address, 1), 32).toLowerCase());
    });
});