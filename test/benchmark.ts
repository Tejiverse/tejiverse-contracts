import { ethers } from "hardhat";
import MerkleTree from "merkletreejs";
import keccak256 from "keccak256";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Tejiverse, TejiverseRenderer } from "../typechain";
import getLayers from "../src/getLayers";
import deployProxy from "../src/deployProxy";

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

      tejiverse = (await deployProxy("Tejiverse")) as Tejiverse;
      tejiverse = tejiverse.connect(addr1);

      await tejiverse
        .connect(owner)
        .initalize(
          "0x0000000000000000000000000000000000000000",
          "",
          tree.getHexRoot(),
        );
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

      renderer = (await deployProxy("TejiverseRenderer")) as TejiverseRenderer;
    });

    it("setLayers()", async () => {
      const layers = getLayers();
      for (let i = 0; i < layers.length; i += layers.length / 4) {
        await renderer.setLayers(layers.slice(i, i + layers.length / 4));
      }
    });
  });
});
