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

  it("claim()", async () => {
    await tejiverse.connect(owner).setSaleState(2);
    await tejiverse.claim();
  });

  it("claimWhitelist()", async () => {
    await tejiverse.connect(owner).setSaleState(1);

    await tejiverse.claimWhitelist(await genSignature(addr1.address));
  });
});
