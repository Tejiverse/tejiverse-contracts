// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "sol-temple/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Tejiverse
/// @author naomsa <https://twitter.com/naomsa666>
/// @author Teji <https://twitter.com/0xTeji>
contract Tejiverse is Ownable, ERC721 {
  using Strings for uint256;
  using ECDSA for bytes32;

  /* -------------------------------------------------------------------------- */
  /*                                Token Details                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Max supply.
  uint256 public constant TEJI_MAX = 1000;

  /* -------------------------------------------------------------------------- */
  /*                              Metadata Details                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Unrevealed metadata URI.
  string public unrevealedURI;

  /// @notice Metadata base URI.
  string public baseURI;

  /* -------------------------------------------------------------------------- */
  /*                             Marketplace Details                            */
  /* -------------------------------------------------------------------------- */

  /// @notice OpenSea proxy registry.
  address public opensea;

  /// @notice LooksRare marketplace transfer manager.
  address public looksrare;

  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved;

  /* -------------------------------------------------------------------------- */
  /*                                Sale Details                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Whitelist verified signer address.
  address public signer;

  /// @notice 0 = CLOSED, 1 = WHITELIST, 2 = PUBLIC.
  uint256 public saleState;

  /// @notice address => has minted on presale.
  mapping(address => bool) internal _boughtPresale;

  constructor(string memory newUnrevealedURI, address newSigner) ERC721("Tejiverse", "TEJI") {
    unrevealedURI = newUnrevealedURI;
    signer = newSigner;

    marketplacesApproved = true;
    opensea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    looksrare = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Sale Logic                                 */
  /* -------------------------------------------------------------------------- */

  /// @notice Claim one teji.
  function claim() external {
    uint256 supply = totalSupply;
    require(supply < TEJI_MAX, "Tejiverse: max supply exceeded");
    if (msg.sender != owner()) {
      require(saleState == 2, "Tejiverse: public sale is not open");
    }

    _safeMint(msg.sender, supply);
  }

  /// @notice Claim one teji with whitelist proof.
  /// @param signature Whitelist proof signature.
  function claimWhitelist(bytes memory signature) external {
    uint256 supply = totalSupply;
    require(supply < TEJI_MAX, "Tejiverse: max supply exceeded");
    require(saleState == 1, "Tejiverse: whitelist sale is not open");
    require(!_boughtPresale[msg.sender], "Tejiverse: already claimed");

    bytes32 digest = keccak256(abi.encodePacked(address(this), msg.sender));
    require(digest.toEthSignedMessageHash().recover(signature) == signer, "Tejiverse: invalid signature");

    _boughtPresale[msg.sender] = true;
    _safeMint(msg.sender, supply);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set unrevealedURI to `newUnrevealedURI`.
  /// @param newUnrevealedURI New unrevealed uri.
  function setUnrevealedURI(string memory newUnrevealedURI) external onlyOwner {
    unrevealedURI = newUnrevealedURI;
  }

  /// @notice Set baseURI to `newBaseURI`.
  /// @param newBaseURI New base uri.
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
    delete unrevealedURI;
  }

  /// @notice Set `saleState` to `newSaleState`.
  /// @param newSaleState New sale state.
  function setSaleState(uint256 newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice Set `signer` to `newSigner`.
  /// @param newSigner New whitelist signer address.
  function setSigner(address newSigner) external onlyOwner {
    signer = newSigner;
  }

  /// @notice Set `opensea` to `newOpensea` and `looksrare` to `newLooksrare`.
  /// @param newOpensea Opensea's proxy registry contract address.
  /// @param newLooksrare Looksrare's transfer manager contract address.
  function setMarketplaces(address newOpensea, address newLooksrare) external onlyOwner {
    opensea = newOpensea;
    looksrare = newLooksrare;
  }

  /// @notice Toggle pre-approve feature state for sender.
  function toggleMarketplacesApproved() external onlyOwner {
    marketplacesApproved = !marketplacesApproved;
  }

  /* -------------------------------------------------------------------------- */
  /*                                ERC-721 Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice See {ERC721-tokenURI}.
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "ERC721Metadata: query for nonexisting token");

    if (bytes(unrevealedURI).length > 0) return unrevealedURI;
    return string(abi.encodePacked(baseURI, id.toString()));
  }

  /// @notice See {ERC721-isApprovedForAll}.
  /// @dev Modified for opensea and looksrare pre-approve so users can make truly gasless sales.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (!marketplacesApproved) return super.isApprovedForAll(owner, operator);

    return
      operator == address(ProxyRegistry(opensea).proxies(owner)) ||
      operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
