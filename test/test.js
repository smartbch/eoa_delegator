const fs = require('fs');

const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("delegator", function () {

    let owner;
    let vaultCt;
    let delegator, eoa, usd, vault;

    before(async function () {
            [owner] = await ethers.getSigners();
            const token = await ethers.getContractFactory("token");
            usd = await token.deploy();
            const delegatorCt = await ethers.getContractFactory("eoa_delegator_1");
            delegator = await delegatorCt.deploy();
            vaultCt = await ethers.getContractFactory("vault");
            vault = await vaultCt.deploy(usd.address);
            const mock_eoa = await ethers.getContractFactory("mock_eoa");
            eoa = await mock_eoa.deploy(delegator.address, usd.address, vault.address);
        }
    )
    it("approve failed", async function () {
        let contract = vaultCt.attach(eoa.address);
        await expect(contract.work()).to.be.revertedWith("ERC20: transfer amount exceeds balance");
        expect(await usd.balanceOf(vault.address)).to.equal(0n);
        expect(await usd.allowance(eoa.address, vault.address)).to.equal(0n);
    });
    it("normal", async function () {
        await usd.transfer(eoa.address, 2000n * 10n ** 18n);
        expect(await usd.balanceOf(eoa.address)).to.equal(2000n * 10n ** 18n);
        console.log("eoa address:", eoa.address);
        let contract = vaultCt.attach(eoa.address);
        await contract.work()
        expect(await usd.balanceOf(vault.address)).to.equal(100n * 10n ** 18n);
        expect(await usd.allowance(eoa.address, vault.address)).to.equal(0n);
    });
});