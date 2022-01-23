import path from "path";
import fs from "fs";

type LayerInput = {
  name: string;
  data: string;
  layerIndex: number;
  itemIndex: number;
};

export default function getLayers(): LayerInput[] {
  const layers: LayerInput[] = [];

  for (const [layerIndex, traitName] of [
    "Background",
    "Clothes",
    "Eyes",
    "Hat",
    "Mouth",
  ].entries()) {
    const dirpath = path.resolve(__dirname, "../assets", traitName);
    const files = fs.readdirSync(dirpath);

    for (const [itemIndex, f] of files.entries()) {
      const fpath = path.join(dirpath, f);

      const name = path.parse(f).name;
      const data = fs.readFileSync(fpath, "base64");
      const layer: LayerInput = {
        name,
        data,
        layerIndex,
        itemIndex,
      };

      layers.push(layer);
    }
  }

  return layers;
}