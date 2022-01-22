import type MerkleTree from "merkletreejs";

import { generateMerkleTree } from "./merkleTree";
import leaves from "./whitelist.json";

export default function (): MerkleTree {
  const tree = generateMerkleTree(leaves);
  console.log("----------------------------------");
  console.log("Whitelist length: ", leaves.length);
  console.log("Merkle Depth: ", tree.getDepth());
  console.log("Merkle Root: ", tree.getHexRoot());
  console.log("----------------------------------");
  return tree;
}
