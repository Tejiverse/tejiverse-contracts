// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract TejiverseRenderer {
  address[][4] internal _layerData;
  mapping(uint256 => string)[4] internal _layerNames;

  struct Layer {
    string name;
    string data;
  }

  struct LayerInput {
    string name;
    string data;
    uint8 layerIndex;
    uint8 itemIndex;
  }

  struct Teji {
    uint8 clothes;
    uint8 eyes;
    uint8 hat;
    uint8 mouth;
    uint8 background;
  }

  function setLayers(LayerInput[] memory toSet) external {
    for (uint16 i = 0; i < toSet.length; i++) {
      _layerData[toSet[i].layerIndex][toSet[i].itemIndex] = SSTORE2.write(bytes(toSet[i].data));
      _layerNames[toSet[i].layerIndex][toSet[i].itemIndex] = toSet[i].name;
    }
  }

  function getLayer(uint8 layerIndex, uint8 itemIndex) public view returns (Layer memory) {
    return Layer(_layerNames[layerIndex][itemIndex], string(SSTORE2.read(_layerData[layerIndex][itemIndex])));
  }

  function getTeji(uint256 dna) public view returns (Teji memory t) {
    t.clothes = uint8(dna % _layerData[0].length);
    t.eyes = uint8(dna >> 16 % _layerData[1].length);
    t.hat = uint8(dna >> 32 % _layerData[2].length);
    t.mouth = uint8(dna >> 64 % _layerData[3].length);
    t.background = uint8(dna >> 64 % 3);
  }

  function tokenURI(uint256 id, bytes memory dna) external view returns (string memory) {}

  function tokenSVG(uint256 id, bytes memory dna) external view returns (string memory) {}

  function _genAttribute(string memory _type, string memory _value) internal pure returns (string memory) {
    /* solhint-disable-next-line */
    return string(abi.encodePacked('{"trait_type": "', _type, '", "value": "', _value, '"}'));
  }

  function _genImage(string memory _png) internal pure returns (string memory) {
    /* solhint-disable */
    return
      string(
        abi.encodePacked(
          '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
          _png,
          '"/>'
        )
      );
    /* solhint-disable */
  }
}
