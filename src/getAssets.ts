import path from "path";
import fs from "fs";
import { chunk, mapValues } from "lodash";
import {
  hexConcat,
  hexDataLength,
  hexlify,
  BytesLike,
  solidityPack,
} from "ethers/lib/utils";

type Layer = {
  traitName: string;
  itemName: string;
  hexString: string;
  layerIndex: number;
  itemIndex: number;
};

type LayerBytes = {
  layerIndex: BytesLike;
  itemIndex: BytesLike;
  hexString: BytesLike;
  itemName: string;
};

type LayerConcat = {
  itemName: string;
  hexString: string;
  layerIndex: string;
  itemIndex: string;
};

export function getLayers(): Layer[] {
  const layers: Layer[] = [];

  for (const [layerIndex, traitName] of [
    "Background",
    "Base",
    "Clothes",
    "Eyes",
    "Hat",
    "Mouth",
  ].entries()) {
    const dirpath = path.resolve(__dirname, "../assets", traitName);
    const files = fs.readdirSync(dirpath);

    for (const [itemIndex, f] of files.entries()) {
      const fpath = path.join(dirpath, f);

      const itemName = ` ${path.parse(f).name} `;
      const hexString = solidityPack(
        ["string"],
        [fs.readFileSync(fpath, "base64")],
      );
      const layer: Layer = {
        traitName,
        itemName,
        hexString,
        layerIndex,
        itemIndex,
      };

      layers.push(layer);
    }
  }

  return layers;
}

export function concatLayers(layers: Layer[]): LayerConcat[] {
  const layersBytes: LayerBytes[] = layers.map((layer) => ({
    ...layer,
    layerIndex: hexlify(layer.layerIndex),
    itemIndex: hexlify(layer.itemIndex),
    hexString: hexlify(layer.hexString),
  }));

  const layerBytes = hexDataLength(layersBytes[0].hexString);
  console.log(layerBytes);
  const layersPerStorage = Math.floor(24000 / layerBytes);
  const layersConcat = chunk(layersBytes, layersPerStorage).map((traitsChunk) =>
    mapValues(
      traitsChunk.reduce((acc, trait) => ({
        layerIndex: hexConcat([acc.layerIndex, hexlify(trait.layerIndex)]),
        itemIndex: hexConcat([acc.itemIndex, hexlify(trait.itemIndex)]),
        hexString: hexConcat([acc.hexString, hexlify(trait.hexString)]),
        itemName: acc.itemName + "|" + trait.itemName,
      })),
      (value, key) =>
        typeof value === "string" && key === "itemName"
          ? value.split("|")
          : value,
    ),
  );

  return layersConcat as LayerConcat[];
}

export default function getAssets(): LayerConcat[] {
  const layers = getLayers();
  return concatLayers(layers);
}
