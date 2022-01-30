import type { Tejiverse } from "../typechain";
import deployProxy from "../src/deployProxy";
import getTree from "../src/getTree";

async function main() {
  const tree = getTree();

  const [tejiverse, tejiverseImpl] = await deployProxy<Tejiverse>("Tejiverse", [
    "https://ipfs.io/ipfs/QmQmmApSZuoLvWY187yQcbJ5J1y5WUDFaRYqAw8GCoUoeQ",
    tree.getHexRoot(),
  ]);

  console.log("Tejiverse Implementation:", tejiverseImpl.address);
  console.log("Tejiverse:", tejiverse.address);
}

main().catch((error) => {
  console.log(error);
  process.exit(1);
});
