import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Tejiverse } from "../typechain";

describe("Tejiverse", () => {
  let [owner, addr1]: SignerWithAddress[] = [];

  let tejiverse: Tejiverse;
  let genSignature: (account: string) => Promise<string>;

  beforeEach(async () => {
    [owner, addr1] = await ethers.getSigners();

    tejiverse = await (
      await ethers.getContractFactory("Tejiverse")
    ).deploy("", owner.address);

    genSignature = async (account: string) => {
      const message = ethers.utils.solidityKeccak256(
        ["address", "address"],
        [tejiverse.address, account],
      );
      return await owner.signMessage(ethers.utils.arrayify(message));
    };

    tejiverse = tejiverse.connect(addr1);
  });

  describe("claim()", () => {
    beforeEach(async () => await tejiverse.connect(owner).setSaleState(2));

    it("Should claim a token from public sale", async () => {
      await tejiverse.claim();

      expect(await tejiverse.balanceOf(addr1.address)).to.equal(1);
      expect(await tejiverse.ownerOf(0)).to.equal(addr1.address);
      expect(await tejiverse.totalSupply()).to.equal(1);
    });

    it("Should revert on invalid sale state", async () => {
      await tejiverse.connect(owner).setSaleState(1);

      await expect(tejiverse.claim()).to.be.revertedWith(
        "Tejiverse: public sale is not open",
      );
    });
  });

  describe("claimWhitelist()", () => {
    beforeEach(async () => await tejiverse.connect(owner).setSaleState(1));

    it("Should claim a token from whitelist", async () => {
      await tejiverse.claimWhitelist(await genSignature(addr1.address));

      expect(await tejiverse.balanceOf(addr1.address)).to.equal(1);
      expect(await tejiverse.ownerOf(0)).to.equal(addr1.address);
      expect(await tejiverse.totalSupply()).to.equal(1);
    });

    it("Should revert on invalid sale state", async () => {
      await tejiverse.connect(owner).setSaleState(0);

      await expect(
        tejiverse.claimWhitelist(await genSignature(addr1.address)),
      ).to.be.revertedWith("Tejiverse: whitelist sale is not open");
    });

    it("Should revert when already minted", async () => {
      await tejiverse.claimWhitelist(await genSignature(addr1.address));

      await expect(
        tejiverse.claimWhitelist(await genSignature(addr1.address)),
      ).to.be.revertedWith("Tejiverse: already claimed");
    });

    it("Should revert with invalid signature", async () => {
      await expect(
        tejiverse.claimWhitelist(await genSignature(owner.address)),
      ).to.be.revertedWith("Tejiverse: invalid signature");
    });
  });
});
