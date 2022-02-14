import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Tejiverse } from "../typechain";
import { BigNumberish } from "ethers";

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

  it("claim()", async () => {
    await tejiverse.connect(owner).setSaleState(2);
    await tejiverse.claim(await tejiverse.TEJI_PER_TX());
  });

  it("claimWhitelist()", async () => {
    await tejiverse.connect(owner).setSaleState(1);

    const perTX = await tejiverse.TEJI_PER_TX();
    await tejiverse.claimWhitelist(
      perTX,
      await genSignature(addr1.address, perTX),
    );
  });
});
