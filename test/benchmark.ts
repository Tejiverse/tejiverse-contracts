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
