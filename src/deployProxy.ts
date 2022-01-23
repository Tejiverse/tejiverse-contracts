import { Contract } from "ethers";
import { ethers } from "hardhat";

export default async function deployProxy(factory: string): Promise<Contract> {
  const implementation = await (
    await ethers.getContractFactory(factory)
  ).deploy();
  await implementation.deployed();

  const proxy = await (
    await ethers.getContractFactory("Proxy")
  ).deploy(implementation.address);
  await proxy.deployed();

  return await ethers.getContractAt(factory, proxy.address);
}
