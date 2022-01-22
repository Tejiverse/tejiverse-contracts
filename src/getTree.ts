import { solidityKeccak256 } from "ethers/lib/utils";
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";

import leaves from "./whitelist.json";

export function hashAccount(account: string): Buffer {
  return Buffer.from(solidityKeccak256(["address"], [account]).slice(2), "hex");
}

export function generateMerkleTree(accounts: string[]): MerkleTree {
  return new MerkleTree(accounts.map(hashAccount), keccak256, {
    sortPairs: true,
  });
}

export default function (): MerkleTree {
  const tree = generateMerkleTree(leaves);
  console.log("----------------------------------");
  console.log("Whitelist length: ", leaves.length);
  console.log("Merkle Depth: ", tree.getDepth());
  console.log("Merkle Root: ", tree.getHexRoot());
  console.log("----------------------------------");
  return tree;
}
