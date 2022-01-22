import { expect } from "chai";
import { ethers } from "hardhat";
import MerkleTree from "merkletreejs";
import keccak256 from "keccak256";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Tejiverse, TejiverseRenderer } from "../typechain";
import getLayers from "../src/getLayers";

function hashAccount(account: string) {
  return Buffer.from(
    ethers.utils.solidityKeccak256(["address"], [account]).slice(2),
    "hex",
  );
}

describe("Tejiverse", () => {
  let [owner, addr1]: SignerWithAddress[] = [];

  describe("NFT", () => {
    let tree: MerkleTree;
    let tejiverse: Tejiverse;

    beforeEach(async () => {
      [owner, addr1] = await ethers.getSigners();

      tree = new MerkleTree(
        [owner.address, addr1.address].map((address) => hashAccount(address)),
        keccak256,
        { sortPairs: true },
      );

      const tejiverseImpl = await (
        await ethers.getContractFactory("Tejiverse")
      ).deploy();

      const proxy = await (
        await ethers.getContractFactory("Proxy")
      ).deploy(tejiverseImpl.address);

      tejiverse = await ethers.getContractAt("Tejiverse", proxy.address);
      await tejiverse.initalize("unrevealedURI", tree.getHexRoot());
      tejiverse = tejiverse.connect(addr1);
    });

    describe("constructor", () => {
      it("Should have set all variables and mint reserve tokens", async () => {
        expect(await tejiverse.unrevealedURI()).to.equal("unrevealedURI");

        expect(await tejiverse.totalSupply()).to.equal(1);
        expect(await tejiverse.balanceOf(owner.address)).to.equal(1);
        expect(await tejiverse.ownerOf(0)).to.equal(owner.address);
      });
    });

    describe("tokenURI()", () => {
      it("Should return the unrevealedURI", async () => {
        expect(await tejiverse.tokenURI(0)).to.equal("unrevealedURI");
      });

      it("Should set the new unrevealedURI", async () => {
        await tejiverse.connect(owner).setUnrevealedURI("soonRevealedURI");
        expect(await tejiverse.tokenURI(0)).to.equal("soonRevealedURI");
      });

      it("Should set the baseURI and baseExtension and reveal", async () => {
        await tejiverse.connect(owner).setBaseURI("baseURI/", ".json");
        expect(await tejiverse.tokenURI(0)).to.equal("baseURI/0.json");
        expect(await tejiverse.unrevealedURI()).to.equal("");
      });
    });

    describe("claim()", () => {
      beforeEach(async () => await tejiverse.connect(owner).setSaleState(2));

      it("Should claim a token from public sale", async () => {
        await tejiverse.claim(1);

        expect(await tejiverse.balanceOf(addr1.address)).to.equal(1);
        expect(await tejiverse.ownerOf(1)).to.equal(addr1.address);
        expect(await tejiverse.totalSupply()).to.equal(2);
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
        expect(await tejiverse.ownerOf(1)).to.equal(addr1.address);
        expect(await tejiverse.totalSupply()).to.equal(2);
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

  describe("Renderer", () => {
    let renderer: TejiverseRenderer;

    beforeEach(async () => {
      [owner, addr1] = await ethers.getSigners();

      renderer = await (
        await ethers.getContractFactory("TejiverseRenderer")
      ).deploy();
    });

    it("Should set layers", async () => {
      const layers = getLayers();
      await renderer.setLayers(layers.slice(0, 10));

      for (let i = 0; i < 10; i++) {
        expect((await renderer.getLayer(0, i)).name).to.equal(layers[i].name);
        expect((await renderer.getLayer(0, i)).data).to.equal(layers[i].data);
      }
    });
  });
});
