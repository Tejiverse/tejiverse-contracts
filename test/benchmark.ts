import { ethers } from "hardhat";
import MerkleTree from "merkletreejs";
import keccak256 from "keccak256";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Tejiverse, TejiverseRenderer } from "../typechain";
import unrevealedURI from "../assets/unrevealed.json";
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
      await tejiverse.initalize(
        JSON.stringify(unrevealedURI),
        tree.getHexRoot(),
      );
      tejiverse = tejiverse.connect(addr1);
    });

    it("claim()", async () => {
      await tejiverse.connect(owner).setSaleState(2);

      await tejiverse.claim(3);
    });

    it("claimWhitelist()", async () => {
      await tejiverse.connect(owner).setSaleState(1);

      await tejiverse.claimWhitelist(
        3,
        tree.getHexProof(hashAccount(addr1.address)),
      );
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

    it("setLayers()", async () => {
      const layers = getLayers();
      for (let i = 0; i < layers.length; i += 10) {
        console.log(i);
        await renderer.setLayers(layers.slice(i, i + 10));
      }
    });
  });
});
