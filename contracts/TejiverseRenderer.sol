// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "base64-sol/base64.sol";
import "sol-temple/src/utils/Upgradable.sol";
import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./TejiverseTypes.sol";

/**
 * @title TejiverseRenderer
 * @author naomsa <https://twitter.com/naomsa666>
 * @author Teji <https://twitter.com/0xTeji>
 */
contract TejiverseRenderer is Upgradable {
  using Strings for uint256;

  struct LayerInput {
    string data;
    uint8 layerIndex;
    uint8 itemIndex;
  }

  /// @notice Array of all encoded layers.
  mapping(uint256 => address)[4] internal _layerData;

  /// @notice Set or edit multiple layers.
  function setLayers(LayerInput[] memory toSet) external onlyOwner {
    for (uint16 i = 0; i < toSet.length; i++) {
      _layerData[toSet[i].layerIndex][toSet[i].itemIndex] = SSTORE2.write(bytes(toSet[i].data));
    }
  }

  /// @notice Get data for layer with `layerIndex` and `itemIndex` coordinates.
  function getLayer(uint8 layerIndex, uint8 itemIndex) external view returns (string memory) {
    return string(SSTORE2.read(_layerData[layerIndex][itemIndex]));
  }

  /// @notice Get background name.
  function getBackgroundName(uint8 index) public pure returns (string memory) {
    return
      index == 0 ? "Blueberry" : index == 1 ? "Cucumber" : index == 2 ? "Lavender" : index == 3
        ? "Lemonade"
        : "Marshmallow";
  }

  /// @notice Get clothes name.
  function getClothesName(uint8 index) public pure returns (string memory) {
    return
      index == 0 ? "Basketball" : index == 1 ? "Bra" : index == 2 ? "Bully" : index == 3 ? "Burger" : index == 4
        ? "CEO"
        : index == 5
        ? "Emoji"
        : index == 6
        ? "Fight club"
        : index == 7
        ? "Funky"
        : index == 8
        ? "Ghillie suit"
        : index == 9
        ? "Hazmat"
        : index == 10
        ? "Hypebeast"
        : index == 11
        ? "Intern"
        : index == 12
        ? "None"
        : index == 13
        ? "Overalls"
        : index == 14
        ? "Pink polo"
        : index == 15
        ? "Priest"
        : index == 16
        ? "Prisioner"
        : index == 17
        ? "Punk"
        : index == 18
        ? "Rainbow"
        : index == 19
        ? "Robe"
        : index == 20
        ? "Sailor"
        : index == 21
        ? "Sundress"
        : index == 22
        ? "The answer"
        : index == 23
        ? "Tradie"
        : index == 24
        ? "Trippy"
        : index == 25
        ? "Turtle"
        : "Underpants";
  }

  /// @notice Get mouth name.
  function getMouthName(uint8 index) public pure returns (string memory) {
    return
      index == 0 ? "Bite" : index == 1 ? "Bubblegum" : index == 2 ? "Buck teeth" : index == 3 ? "Chicken" : index == 4
        ? "Cigarette"
        : index == 5
        ? "Grin"
        : index == 6
        ? "Grr"
        : index == 7
        ? "Infected"
        : index == 8
        ? "Lipstick"
        : index == 9
        ? "Meh"
        : index == 10
        ? "Moustache"
        : index == 11
        ? "Normal"
        : index == 12
        ? "Sad boy"
        : "Wazzuupp";
  }

  /// @notice Get eyes name.
  function getEyesName(uint8 index) public pure returns (string memory) {
    return
      index == 0 ? "3D" : index == 1 ? "Aviators" : index == 2 ? "Balaclava" : index == 3 ? "Black eye" : index == 4
        ? "C.R.E.A.M."
        : index == 5
        ? "Cool guy"
        : index == 6
        ? "Crying"
        : index == 7
        ? "Drowsy"
        : index == 8
        ? "Eye patch"
        : index == 9
        ? "Hockey mask"
        : index == 10
        ? "Huh"
        : index == 11
        ? "Kawaii"
        : index == 12
        ? "Monocle"
        : index == 13
        ? "Night vision"
        : index == 14
        ? "Normal"
        : index == 15
        ? "Nouns"
        : index == 16
        ? "Robo"
        : index == 17
        ? "Scouter"
        : index == 18
        ? "Shutter shades"
        : index == 19
        ? "Spectacles"
        : index == 20
        ? "Squint"
        : index == 21
        ? "Stoned"
        : index == 22
        ? "TV"
        : index == 23
        ? "Villain"
        : index == 24
        ? "Vlogger"
        : index == 25
        ? "VR"
        : "Wink";
  }

  /// @notice Get hat name.
  function getHatName(uint8 index) public pure returns (string memory) {
    return
      index == 0 ? "Aloha" : index == 1 ? "Baseball cap" : index == 2 ? "Cowboy" : index == 3 ? "Crown" : index == 4
        ? "Durag"
        : index == 5
        ? "Enlightened"
        : index == 6
        ? "Hard hat"
        : index == 7
        ? "Headband"
        : index == 8
        ? "Knitted"
        : index == 9
        ? "None"
        : index == 10
        ? "Tinfoil"
        : index == 11
        ? "Top hat"
        : index == 12
        ? "Trucker cap"
        : index == 13
        ? "Wizard"
        : "Wounded";
  }

  /// @notice Get Teji structure data by given `dna`.
  function getTeji(uint256 dna) public pure returns (TejiverseTypes.Teji memory t) {
    t.background = uint8((dna >> 8) % 5);
    t.clothes = uint8((dna >> 16) % 27);
    t.mouth = uint8((dna >> 32) % 14);
    t.eyes = uint8((dna >> 64) % 27);
    t.hat = uint8((dna >> 128) % 15);
  }

  /// @notice Retrieve tokenURI for given token `id` and `dna`.
  function tokenURI(TejiverseTypes.Teji memory teji, uint256 id) external view returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string(
                abi.encodePacked(
                  '{"name": "Teji #',
                  id.toString(),
                  '","description":"","image":"',
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
  }

  /// @notice Retrieve token SVG for given `teji` traits.
  function tokenSVG(TejiverseTypes.Teji memory teji) public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '<svg id="teji" width="100%" height="100%" version="1.1" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                _genBackground(teji.background),
                '<image x="0" y="0" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAABVxJREFUWEfFln1MVWUcxz/P4XIvoJCaYoAs0GZm459oWTmDbNakcpbv6cqQNyesFbgpGfdeLHALcg0QleZLQ4dvYU10zunM5nQ2qz+yrGYwEV/DtyvCucB92jnnXu6Fe69y+cdnOzt35z7n+X1+39/395xH8IiHeMTxGRJAmIU3exUi6fXBF3Si0hRqQqEDhPMCCoeZmT+iX7BD1bdx8QbdnAkFInQAEzbxbqFVLq2AehsgYYkdthXBd5V2etAeDnoEBgjnfRSm6QWS2qVcwekq0Vc1YWN7q5WR4yBD0SeIgxJ58xIsTfQCmClFENe3houf6ObbgWQDARQsfIKiWFl7YjijE+DOdVg9tZvengOozMdEMWMTbdReELRfAi3C6ARE3gQpr7Xa6KEMM7sxmd6i/GQ4j8VCexusSbuHq9eOyleAywPSH8BCPiZzFcs3wfSl+hxdhLbzUJgK6v0fUUnHwnngaRo1eYB39GX+QmUSFo5jiUqj8iwkTHIvABzbBrW50OMsQKU6OMBCWxULrCAktF9FKApy+OPwyyEom3UKZ9QcuC+w0MaWy8Y6mQmgygS9Hmaxj+LvXyJ1JjjaQbpg5BNGIrtKocEWHECxkO+auaKKxZ+DJQrmWRAxY5AFW+DL+RCb5FVFN0cQD19vgZW7oSoT7t5A7OlCqp2IHWuQTTUFdAdRIMzMnF6F9eRtTmT6h1A8FZp/hQnPw5Mp6KVxD48/+5nK83BDDlz8HXHhZ2Tyc1B+Eo5thQ05rSh8TCf7ApdAe2rGzuyiEhaVwrnjUL0MtraBFN56DrCyJ65HD7czIDMO8rfAs69Cw2fQWFGKE6vv6/4aRpCOiwoyVqRypA4Wl8HswgEhHyC/PlMiEMj9lbCjGGZkw8GasygU0cXxBwMY/44gQruim9l5N3BwzaSaB/rSDbL3vBcDtx3JwG335Ve1wG9aaCYyOskA8GYskHp+nhbV8w1oCLdHF8VAl6OFLjQIvxF8Kx5mbmavmqTFFlqifZk+TP4AUeZZWuhwDgFgT1dSsFbzJfergq8i2u+5QwZQjcb3mGpgcgGl90jmM3koCgitBJuak+So+ACaul3uMUI/CTwlct9vXYac5NBLoFgodJnMFcwp7gN44OYTpAnYVw49ahEqlSGZUIlglys8cj5rmnQX9gX3o/BRw/Px8ty1uaUZ0N25my4WhARAVHizKDuRJCe+6POeVl933/mA+Cvj07Z/n4biaars6bHhZF0gG/mDmSgV5vBVcq8z3HcPCKay1wpBWvS3I2B//RtUsgcHEEGdWHc6S06cYsx3p2gkL907j9Edfm0ayCjX/oW8CSEAWKhj2Igs6m95az8wmOICl3Yke8hYFgcdDlA7QgCAMCI5IcIsL8tRCWAyo5tRV8N3W/Z+CvTED3wNpxrBHGHMbW9FOLsuSpVnABX6HeT7xA3kgWmEMZnI6I3UXYLthUE/xX4vz14J8RONx5nxcOtKAZL/cNIwuC6IIF24qJBvf5SqHyjneveBvgUa10Onw3+9lFcgJd1btv0Vxry9X7TQ2TvIb4EJO+mLS1heC5HRcP8O/FANCz81VDjTxPCOf1DMJj8A9doN1ClLIP4paCiDWQUQFQPzzA66u/NwsvPhXWDCLgrqSuSMLMPlN6/C6tdg0znD8fVWxmRnYxo7rv9aAu7V2HEkpkNKGuROhvKjMCoODm+GjbmDNKF2JFtRV4IOANy84gb4wzDNDiujs7IJG5ugn3o8Q2vPjpq1OBLT/AGuN0Pu+FABlhkZawCrpsPmP41Y9VaUnA+IjR3vdya+V2vHMc6rgCg/itQU0E7JuckBAf4HyQvnMOoPw/UAAAAASUVORK5CYII="/>',
                _genImage(0, teji.clothes),
                _genImage(1, teji.mouth),
                _genImage(2, teji.eyes),
                _genImage(3, teji.hat),
                "<style>#teji{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
              )
            )
          )
        )
      );
  }

  /// @notice Generate attribute element for metadata.
  function _genAttributes(TejiverseTypes.Teji memory teji) internal pure returns (string memory) {
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

  /// @notice Generate the background <rect/> element.
  function _genBackground(uint8 backgroundIndex) internal pure returns (string memory) {
    string memory color = backgroundIndex == 0 ? "76D3FE" : backgroundIndex == 1 ? "51EBA1" : backgroundIndex == 2
      ? "C5AFFF"
      : backgroundIndex == 3
      ? "F3E97F"
      : "FF95DF";

    return string(abi.encodePacked('<rect x="0" y="0" width="100%" height="100%" fill="#', color, '"/>'));
  }
}
