import { ethers } from "hardhat";

import getTree from "../src/getTree";

async function main() {
  const tree = getTree();

  const tejiverseImpl = await (
    await ethers.getContractFactory("Tejiverse")
  ).deploy();
  await tejiverseImpl.deployed();
  console.log("Tejiverse Implementation:", tejiverseImpl.address);

  const proxy = await (
    await ethers.getContractFactory("Proxy")
  ).deploy(tejiverseImpl.address);
  await proxy.deployed();
  console.log("Tejiverse:", proxy.address);

  await (
    await ethers.getContractAt("Tejiverse", proxy.address)
  ).initalize("", tree.getHexRoot());
}

main().catch((error) => {
  console.log(error);
  process.exit(1);
});
