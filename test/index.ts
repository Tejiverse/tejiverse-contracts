import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumberish } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Tejiverse } from "../typechain";

describe("Tejiverse", () => {
  let [owner, addr1]: SignerWithAddress[] = [];

  let tejiverse: Tejiverse;
  let genSignature: (account: string, amount: BigNumberish) => Promise<string>;

  beforeEach(async () => {
    [owner, addr1] = await ethers.getSigners();

    tejiverse = await (
      await ethers.getContractFactory("Tejiverse")
    ).deploy("", owner.address);

    genSignature = async (account: string, amount: BigNumberish) => {
      const message = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256"],
        [tejiverse.address, account, amount],
      );
      return await owner.signMessage(ethers.utils.arrayify(message));
    };

    tejiverse = tejiverse.connect(addr1);
  });

  describe("claim()", () => {
    beforeEach(async () => await tejiverse.connect(owner).setSaleState(2));

    it("Should claim a token from public sale", async () => {
      await tejiverse.claim(1);

      expect(await tejiverse.balanceOf(addr1.address)).to.equal(1);
      expect(await tejiverse.ownerOf(0)).to.equal(addr1.address);
      expect(await tejiverse.totalSupply()).to.equal(1);
    });

    it("Should revert on invalid sale state", async () => {
      await tejiverse.connect(owner).setSaleState(1);

      await expect(tejiverse.claim(1)).to.be.revertedWith(
        "Tejiverse: public sale is not open",
      );
    });

    it("Should revert with invalid claim amount", async () => {
      await expect(tejiverse.claim(0)).to.be.revertedWith(
        "Tejiverse: invalid claim amount",
      );

      await expect(tejiverse.claim(11)).to.be.revertedWith(
        "Tejiverse: invalid claim amount",
      );
    });
  });

  describe("claimWhitelist()", () => {
    beforeEach(async () => await tejiverse.connect(owner).setSaleState(1));

    it("Should claim a token from whitelist", async () => {
      await tejiverse.claimWhitelist(1, await genSignature(addr1.address, 1));

      expect(await tejiverse.balanceOf(addr1.address)).to.equal(1);
      expect(await tejiverse.ownerOf(0)).to.equal(addr1.address);
      expect(await tejiverse.totalSupply()).to.equal(1);
    });

    it("Should revert on invalid sale state", async () => {
      await tejiverse.connect(owner).setSaleState(0);

      await expect(
        tejiverse.claimWhitelist(1, await genSignature(addr1.address, 1)),
      ).to.be.revertedWith("Tejiverse: whitelist sale is not open");
    });

    it("Should revert with invalid claim amount", async () => {
      await expect(
        tejiverse.claimWhitelist(0, await genSignature(addr1.address, 1)),
      ).to.be.revertedWith("Tejiverse: invalid claim amount");

      await expect(
        tejiverse.claimWhitelist(11, await genSignature(addr1.address, 1)),
      ).to.be.revertedWith("Tejiverse: invalid claim amount");
    });

    it("Should revert when minted max amount", async () => {
      const perTX = await tejiverse.TEJI_PER_TX();
      await tejiverse.claimWhitelist(
        perTX,
        await genSignature(addr1.address, perTX),
      );

      await expect(
        tejiverse.claimWhitelist(1, await genSignature(addr1.address, 1)),
      ).to.be.revertedWith("Tejiverse: invalid claim amount");
    });

    it("Should revert with invalid signature", async () => {
      await expect(
        tejiverse.claimWhitelist(1, await genSignature(owner.address, 1)),
      ).to.be.revertedWith("Tejiverse: invalid signature");
    });
  });
});
