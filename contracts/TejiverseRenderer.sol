// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract TejiverseRenderer {
  address[] internal _layerHexStrings;
  address[] internal _layerLayerIndexes;
  address[] internal _layerItemIndexes;
  string[] internal _layerNames;

  struct Layer {
    string name;
    bytes hexString;
  }

  struct LayerInputConcat {
    string[] name;
    bytes hexString;
    bytes layerIndex;
    bytes itemIndex;
  }

  function setLayers(LayerInputConcat[] memory layers) external {
    for (uint8 i = 0; i < layers.length; i++) {
      for (uint8 j = 0; j < layers[i].name.length; j++) {
        _layerNames.push(layers[i].name[j]);
      }
      _layerHexStrings.push(SSTORE2.write(layers[i].hexString));
      _layerLayerIndexes.push(SSTORE2.write(layers[i].layerIndex));
      _layerItemIndexes.push(SSTORE2.write(layers[i].itemIndex));
    }
  }

  function getLayer(uint8 layerIndex, uint8 itemIndex) public view returns (Layer memory) {
    // storageIndex is the index of the SSTORE2 containing the data
    uint8 storageIndex = 0;
    bytes memory layerIndexes = SSTORE2.read(_layerLayerIndexes[storageIndex]);
    uint8 lastLayerIndex = uint8(layerIndexes[layerIndexes.length - 1]);

    // Since layerIndexes are sorted, we only look at the last byte to check if this storageIndex
    // is the one we are looking for
    while (lastLayerIndex < layerIndex) {
      storageIndex++;
      layerIndexes = SSTORE2.read(_layerLayerIndexes[storageIndex]);
      lastLayerIndex = uint8(layerIndexes[layerIndexes.length - 1]);
    }

    // Load the corresponding item indexes for the given storageIndex
    bytes memory itemIndexes = SSTORE2.read(_layerItemIndexes[storageIndex]);

    // Actually the items for this layerIndex may be split between this storageIndex and the one after
    // So we check if the itemIndex is in the range of the itemIndexes for this storageIndex
    if (lastLayerIndex == layerIndex) {
      if (itemIndex > uint8(itemIndexes[itemIndexes.length - 1])) {
        storageIndex++;
        layerIndexes = SSTORE2.read(_layerLayerIndexes[storageIndex]);
        itemIndexes = SSTORE2.read(_layerItemIndexes[storageIndex]);
      }
    }

    uint8 currentStorageShiftCount = 0;
    while (uint8(layerIndexes[currentStorageShiftCount]) < layerIndex) {
      currentStorageShiftCount++;
    }
    while (
      (uint8(itemIndexes[currentStorageShiftCount]) < itemIndex) &&
      (uint8(layerIndexes[currentStorageShiftCount]) == layerIndex)
    ) {
      currentStorageShiftCount++;
    }
    if (uint8(itemIndexes[currentStorageShiftCount]) < itemIndex) {
      // Layer not found, return empty layer to match ChainRunnersBaseRenderer empty layer with mapping
      return Layer("", "");
    }

    bytes memory storageHexStrings = SSTORE2.read(_layerHexStrings[storageIndex]);
    bytes memory hexString = new bytes(416);
    for (uint16 i = 0; i < 416; i++) {
      hexString[i] = storageHexStrings[i + 416 * currentStorageShiftCount];
    }

    uint16 nameIndex = uint16(storageIndex) * 57 + uint16(currentStorageShiftCount);
    string memory name = _layerNames[nameIndex];
    return Layer(name, hexString);
  }
}
