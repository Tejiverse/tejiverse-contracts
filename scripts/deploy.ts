import { Tejiverse, TejiverseRenderer } from "../typechain";
import deployProxy from "../src/deployProxy";
import getTree from "../src/getTree";
import getLayers from "../src/getLayers";

async function main() {
  const tree = getTree();

  const tejiverse = (await deployProxy("Tejiverse")) as Tejiverse;
  console.log("Tejiverse:", tejiverse.address);

  const renderer = (await deployProxy(
    "TejiverseRenderer",
  )) as TejiverseRenderer;
  console.log("Renderer:", renderer.address);

  const layers = getLayers();
  for (let i = 0; i < layers.length; i += 10) {
    await renderer.setLayers(layers.slice(i, i + 10));
  }

  await tejiverse.initalize(
    renderer.address,
    "https://ipfs.io/ipfs/QmQmmApSZuoLvWY187yQcbJ5J1y5WUDFaRYqAw8GCoUoeQ",
    tree.getHexRoot(),
  );
}

main().catch((error) => {
  console.log(error);
  process.exit(1);
});
