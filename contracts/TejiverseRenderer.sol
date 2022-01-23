// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "base64-sol/base64.sol";
import "sol-temple/src/utils/Upgradable.sol";
import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./TejiverseTypes.sol";

contract TejiverseRenderer is Upgradable {
  using Strings for uint256;

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

  /// @notice Array of all encoded layers.
  mapping(uint256 => address)[5] internal _layerData;
  /// @notice Array of all encoded names.
  mapping(uint256 => address)[5] internal _layerNames;

  /// @notice Set or edit multiple layers.
  function setLayers(LayerInput[] memory toSet) external onlyOwner {
    for (uint16 i = 0; i < toSet.length; i++) {
      _layerData[toSet[i].layerIndex][toSet[i].itemIndex] = SSTORE2.write(bytes(toSet[i].data));
      _layerNames[toSet[i].layerIndex][toSet[i].itemIndex] = SSTORE2.write(bytes(toSet[i].name));
    }
  }

  /// @notice Get layer info with `layerIndex` and `itemIndex`.
  function getLayer(uint8 layerIndex, uint8 itemIndex) public view returns (Layer memory) {
    return
      Layer(
        string(SSTORE2.read(_layerNames[layerIndex][itemIndex])),
        string(SSTORE2.read(_layerData[layerIndex][itemIndex]))
      );
  }

  /// @notice Get background name.
  function getBackgroundName(uint8 index) public view returns (string memory) {
    return string(SSTORE2.read(_layerNames[0][index]));
  }

  /// @notice Get clothes name.
  function getClothesName(uint8 index) public view returns (string memory) {
    return string(SSTORE2.read(_layerNames[1][index]));
  }

  /// @notice Get eyes name.
  function getEyesName(uint8 index) public view returns (string memory) {
    return string(SSTORE2.read(_layerNames[2][index]));
  }

  /// @notice Get hat name.
  function getHatName(uint8 index) public view returns (string memory) {
    return string(SSTORE2.read(_layerNames[3][index]));
  }

  /// @notice Get mouth name.
  function getMouthName(uint8 index) public view returns (string memory) {
    return string(SSTORE2.read(_layerNames[4][index]));
  }

  /// @notice Get Teji structure data by given `dna`.
  function getTeji(uint256 dna) public pure returns (TejiverseTypes.Teji memory t) {
    t.background = uint8((dna >> 8) % 5);
    t.clothes = uint8((dna >> 16) % 27);
    t.eyes = uint8((dna >> 32) % 27);
    t.hat = uint8((dna >> 64) % 15);
    t.mouth = uint8((dna >> 128) % 14);
  }

  /// @notice Retrieve tokenURI for given token `id` and `dna`.
  function tokenURI(TejiverseTypes.Teji memory teji, uint256 id) external view returns (string memory) {
    /* solhint-disable */
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string(
                abi.encodePacked(
                  '{"name": "Tejiverse #',
                  id.toString(),
                  '","description":"Tejiverse is an awesome...","image":"',
                  tokenSVG(teji),
                  '",',
                  _genAttributes(teji),
                  "}"
                )
              )
            )
          )
        )
      );
    /* solhint-disable */
  }

  /// @notice Retrieve token SVG for given `teji` traits.
  function tokenSVG(TejiverseTypes.Teji memory teji) public view returns (string memory) {
    /* solhint-disable */
    return
      string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '<svg id="teji" width="100%" height="100%" version="1.1" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                _genImage(0, teji.background),
                '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAABVxJREFUWEfFln1MVWUcxz/P4XIvoJCaYoAs0GZm459oWTmDbNakcpbv6cqQNyesFbgpGfdeLHALcg0QleZLQ4dvYU10zunM5nQ2qz+yrGYwEV/DtyvCucB92jnnXu6Fe69y+cdnOzt35z7n+X1+39/395xH8IiHeMTxGRJAmIU3exUi6fXBF3Si0hRqQqEDhPMCCoeZmT+iX7BD1bdx8QbdnAkFInQAEzbxbqFVLq2AehsgYYkdthXBd5V2etAeDnoEBgjnfRSm6QWS2qVcwekq0Vc1YWN7q5WR4yBD0SeIgxJ58xIsTfQCmClFENe3houf6ObbgWQDARQsfIKiWFl7YjijE+DOdVg9tZvengOozMdEMWMTbdReELRfAi3C6ARE3gQpr7Xa6KEMM7sxmd6i/GQ4j8VCexusSbuHq9eOyleAywPSH8BCPiZzFcs3wfSl+hxdhLbzUJgK6v0fUUnHwnngaRo1eYB39GX+QmUSFo5jiUqj8iwkTHIvABzbBrW50OMsQKU6OMBCWxULrCAktF9FKApy+OPwyyEom3UKZ9QcuC+w0MaWy8Y6mQmgygS9Hmaxj+LvXyJ1JjjaQbpg5BNGIrtKocEWHECxkO+auaKKxZ+DJQrmWRAxY5AFW+DL+RCb5FVFN0cQD19vgZW7oSoT7t5A7OlCqp2IHWuQTTUFdAdRIMzMnF6F9eRtTmT6h1A8FZp/hQnPw5Mp6KVxD48/+5nK83BDDlz8HXHhZ2Tyc1B+Eo5thQ05rSh8TCf7ApdAe2rGzuyiEhaVwrnjUL0MtraBFN56DrCyJ65HD7czIDMO8rfAs69Cw2fQWFGKE6vv6/4aRpCOiwoyVqRypA4Wl8HswgEhHyC/PlMiEMj9lbCjGGZkw8GasygU0cXxBwMY/44gQruim9l5N3BwzaSaB/rSDbL3vBcDtx3JwG335Ve1wG9aaCYyOskA8GYskHp+nhbV8w1oCLdHF8VAl6OFLjQIvxF8Kx5mbmavmqTFFlqifZk+TP4AUeZZWuhwDgFgT1dSsFbzJfergq8i2u+5QwZQjcb3mGpgcgGl90jmM3koCgitBJuak+So+ACaul3uMUI/CTwlct9vXYac5NBLoFgodJnMFcwp7gN44OYTpAnYVw49ahEqlSGZUIlglys8cj5rmnQX9gX3o/BRw/Px8ty1uaUZ0N25my4WhARAVHizKDuRJCe+6POeVl933/mA+Cvj07Z/n4biaars6bHhZF0gG/mDmSgV5vBVcq8z3HcPCKay1wpBWvS3I2B//RtUsgcHEEGdWHc6S06cYsx3p2gkL907j9Edfm0ayCjX/oW8CSEAWKhj2Igs6m95az8wmOICl3Yke8hYFgcdDlA7QgCAMCI5IcIsL8tRCWAyo5tRV8N3W/Z+CvTED3wNpxrBHGHMbW9FOLsuSpVnABX6HeT7xA3kgWmEMZnI6I3UXYLthUE/xX4vz14J8RONx5nxcOtKAZL/cNIwuC6IIF24qJBvf5SqHyjneveBvgUa10Onw3+9lFcgJd1btv0Vxry9X7TQ2TvIb4EJO+mLS1heC5HRcP8O/FANCz81VDjTxPCOf1DMJj8A9doN1ClLIP4paCiDWQUQFQPzzA66u/NwsvPhXWDCLgrqSuSMLMPlN6/C6tdg0znD8fVWxmRnYxo7rv9aAu7V2HEkpkNKGuROhvKjMCoODm+GjbmDNKF2JFtRV4IOANy84gb4wzDNDiujs7IJG5ugn3o8Q2vPjpq1OBLT/AGuN0Pu+FABlhkZawCrpsPmP41Y9VaUnA+IjR3vdya+V2vHMc6rgCg/itQU0E7JuckBAf4HyQvnMOoPw/UAAAAASUVORK5CYII="/>',
                _genImage(1, teji.clothes),
                _genImage(2, teji.eyes),
                _genImage(3, teji.hat),
                _genImage(4, teji.mouth),
                "<style>#teji{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
              )
            )
          )
        )
      );
    /* solhint-disable */
  }

  /// @notice Generate attribute element for metadata.
  function _genAttributes(TejiverseTypes.Teji memory teji) internal view returns (string memory) {
    /* solhint-disable */
    return
      string(
        abi.encodePacked(
          '"attributes":[{"trait_type": "Background", "value": "',
          getBackgroundName(teji.background),
          '"},'
          '{"trait_type": "Clothes", "value": "',
          getClothesName(teji.clothes),
          '"},',
          '{"trait_type": "Eyes", "value": "',
          getEyesName(teji.eyes),
          '"},'
          '{"trait_type": "Hat", "value": "',
          getHatName(teji.hat),
          '"},',
          '{"trait_type": "Mouth", "value": "',
          getMouthName(teji.mouth),
          '"}]'
        )
      );
    /* solhint-disable */
  }

  /// @notice Generate <img/> element for metadata.
  function _genImage(uint8 layerIndex, uint8 itemIndex) internal view returns (string memory) {
    /* solhint-disable */
    return
      string(
        abi.encodePacked(
          '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
          SSTORE2.read(_layerData[layerIndex][itemIndex]),
          '"/>'
        )
      );
    /* solhint-disable */
  }
}
