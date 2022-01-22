import { solidityKeccak256 } from "ethers/lib/utils";
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";

export function hashAccount(account: string) {
  return Buffer.from(solidityKeccak256(["address"], [account]).slice(2), "hex");
}

export function generateMerkleTree(accounts: string[]) {
  return new MerkleTree(accounts.map(hashAccount), keccak256, {
    sortPairs: true,
  });
}
