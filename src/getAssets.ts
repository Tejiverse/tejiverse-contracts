import { solidityPack } from "ethers/lib/utils";
import fs from "fs";
import path from "path";

interface LayerInput {
  name: string;
  data: string;
  layerIndex: number;
  itemIndex: number;
}

export default function getAssets(): LayerInput[] {
  const layerInputs: LayerInput[] = [];

  for (const [layerIndex, dir] of [
    "Background",
    "Base",
    "Clothes",
    "Eyes",
    "Hat",
    "Mouth",
  ].entries()) {
    const dirpath = path.resolve(__dirname, "../assets", dir);
    const files = fs.readdirSync(dirpath);

    for (const [itemIndex, f] of files.entries()) {
      const fpath = path.join(dirpath, f);

      const name = solidityPack(["string"], [path.parse(f).name]);
      const data = solidityPack(["string"], [fs.readFileSync(fpath, "base64")]);
      const layer: LayerInput = { name, data, layerIndex, itemIndex };

      layerInputs.push(layer);
    }
  }

  return layerInputs;
}
