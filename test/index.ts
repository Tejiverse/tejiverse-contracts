import { expect } from "chai";
import { ethers } from "hardhat";
import MerkleTree from "merkletreejs";
import keccak256 from "keccak256";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Tejiverse } from "../typechain";
import deployProxy from "../src/deployProxy";

function hashAccount(account: string) {
  return Buffer.from(
    ethers.utils.solidityKeccak256(["address"], [account]).slice(2),
    "hex",
  );
}

describe("Tejiverse", () => {
  let [owner, addr1]: SignerWithAddress[] = [];

  let tree: MerkleTree;
  let tejiverse: Tejiverse;

  beforeEach(async () => {
    [owner, addr1] = await ethers.getSigners();

    tree = new MerkleTree(
      [owner.address, addr1.address].map((address) => hashAccount(address)),
      keccak256,
      { sortPairs: true },
    );

    [tejiverse] = await deployProxy<Tejiverse>("Tejiverse", [
      "unrevealedURI",
      tree.getHexRoot(),
    ]);
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
        "Public sale is not open",
      );
    });

    it("Should revert with invalid claim amount", async () => {
      await expect(tejiverse.claim(0)).to.be.revertedWith(
        "Invalid claim amount",
      );

      await expect(tejiverse.claim(11)).to.be.revertedWith(
        "Invalid claim amount",
      );
    });
  });

  describe("claimWhitelist()", () => {
    beforeEach(async () => await tejiverse.connect(owner).setSaleState(1));

    it("Should claim a token from whitelist", async () => {
      await tejiverse.claimWhitelist(
        1,
        tree.getHexProof(hashAccount(addr1.address)),
      );

      expect(await tejiverse.balanceOf(addr1.address)).to.equal(1);
      expect(await tejiverse.ownerOf(0)).to.equal(addr1.address);
      expect(await tejiverse.totalSupply()).to.equal(1);
    });

    it("Should revert on invalid sale state", async () => {
      await tejiverse.connect(owner).setSaleState(0);

      await expect(
        tejiverse.claimWhitelist(
          1,
          tree.getHexProof(hashAccount(addr1.address)),
        ),
      ).to.be.revertedWith("Whitelist sale is not open");
    });

    it("Should revert with invalid claim amount", async () => {
      await expect(
        tejiverse.claimWhitelist(
          0,
          tree.getHexProof(hashAccount(addr1.address)),
        ),
      ).to.be.revertedWith("Invalid claim amount");

      await expect(
        tejiverse.claimWhitelist(
          11,
          tree.getHexProof(hashAccount(addr1.address)),
        ),
      ).to.be.revertedWith("Invalid claim amount");
    });

    it("Should revert with invalid proof", async () => {
      await expect(
        tejiverse.claimWhitelist(
          1,
          tree.getHexProof(hashAccount(owner.address)),
        ),
      ).to.be.revertedWith("Invalid proof");
    });
  });
});
