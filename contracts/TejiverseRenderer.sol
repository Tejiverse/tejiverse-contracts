// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract TejiverseRenderer {
  mapping(uint256 => address)[6] internal _layersData;
  mapping(uint256 => address)[6] internal _layersNames;

  struct LayerInput {
    bytes name;
    bytes data;
    uint8 layerIndex;
    uint8 itemIndex;
  }

  struct Layer {
    string name;
    string data;
  }

  function setLayers(LayerInput[] memory layers) external {
    for (uint256 i = 0; i < layers.length; i++) {
      _layersData[layers[i].layerIndex][layers[i].itemIndex] = SSTORE2.write(layers[i].data);
      _layersNames[layers[i].layerIndex][layers[i].itemIndex] = SSTORE2.write(layers[i].name);
    }
  }

  function getLayer(uint8 layerIndex, uint8 itemIndex) external view returns (Layer memory) {
    return
      Layer(
        string(SSTORE2.read(_layersNames[layerIndex][itemIndex])),
        string(SSTORE2.read(_layersData[layerIndex][itemIndex]))
      );
  }
}
