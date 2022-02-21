import { ethers, network } from "hardhat";

async function main() {
  const tejiverse = await (
    await ethers.getContractFactory("Tejiverse")
  ).deploy("", "0x7b85FDa7524BAfCf59d02694DdA7F323F7545149");
  await tejiverse.deployed();
  console.log("Tejiverse:", tejiverse.address);

  console.log(
    `\nyarn hardhat verify --network ${network.name} ${tejiverse.address} "" "0x7b85FDa7524BAfCf59d02694DdA7F323F7545149"`,
  );
}

main().catch((error) => {
  console.log(error);
  process.exit(1);
});
