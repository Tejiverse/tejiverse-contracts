import { ethers } from "hardhat";
import type { Contract } from "ethers";

export default async function deployProxy<T extends Contract>(
  factory: string,
  args: any[],
): Promise<T[]> {
  // Deploy the implementation
  const implementation = (await (
    await ethers.getContractFactory(factory)
  ).deploy()) as T;
  await implementation.deployed();

  // Deploy the proxy
  const proxy = await (
    await ethers.getContractFactory("Proxy")
  ).deploy(implementation.address);
  await proxy.deployed();

  // Get the contract at
  const contract = (await ethers.getContractAt(factory, proxy.address)) as T;

  // Initialize the contract
  if (args.length > 0) await (await contract.initialize(...args)).wait();
  else await (await contract.initialize()).wait();

  return [contract, implementation];
}
