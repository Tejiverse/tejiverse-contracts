// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "sol-temple/src/tokens/ERC721Upgradable.sol";
import "sol-temple/src/utils/Upgradable.sol";
import "sol-temple/src/utils/Proxy.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Tejiverse
 * @author naomsa <https://twitter.com/naomsa666> & Teji <https://twitter.com/0xTeji>
 */
contract Tejiverse is Upgradable, ERC721Upgradable {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  /// @notice Max supply.
  uint256 public constant SUPPLY_MAX = 1000;

  /// @notice Max amount per claim (not whitelist).
  uint256 public constant CLAIM_PER_TX = 3;

  /// @notice 0 = CLOSED, 1 = WHITELIST, 2 = PUBLIC.
  uint256 public saleState;

  /// @notice Metadata base URI.
  string public baseURI;

  /// @notice Metadata URI extension.
  string public baseExtension;

  /// @notice Unrevealed metadata URI.
  string public unrevealedURI;

  /// @notice Whitelist merkle root.
  bytes32 public merkleRoot;

  /// @notice Whitelist mints per address.
  mapping(address => uint256) public whitelistMinted;

  /// @notice OpenSea proxy registry.
  address public opensea;

  /// @notice LooksRare marketplace transfer manager.
  address public looksrare;

  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved = true;

  function initalize(string memory unrevealedURI_, bytes32 merkleRoot_) external onlyOwner {
    __ERC721_init("Tejiverse", "TEJI");

    unrevealedURI = unrevealedURI_;
    merkleRoot = merkleRoot_;
    opensea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    looksrare = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;

    _safeMint(msg.sender, 0);
  }

  /// @notice Claim one or more tokens.
  function claim(uint256 amount_) external {
    uint256 supply = totalSupply;
    require(supply + amount_ <= SUPPLY_MAX, "Max supply exceeded");
    if (msg.sender != owner) {
      require(saleState == 2, "Public sale is not open");
      require(amount_ > 0 && amount_ <= CLAIM_PER_TX, "Invalid claim amount");
    }

    for (uint256 i = 0; i < amount_; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice Claim one or more tokens for whitelisted user.
  function claimWhitelist(uint256 amount_, bytes32[] memory proof_) external {
    uint256 supply = totalSupply;
    require(supply + amount_ <= SUPPLY_MAX, "Max supply exceeded");
    if (msg.sender != owner) {
      require(saleState == 1, "Whitelist sale is not open");
      require(amount_ > 0 && amount_ + whitelistMinted[msg.sender] <= CLAIM_PER_TX, "Invalid claim amount");
      require(isWhitelisted(msg.sender, proof_), "Invalid proof");
    }

    whitelistMinted[msg.sender] += amount_;
    for (uint256 i = 0; i < amount_; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice Retrieve if `user_` is whitelisted based on his `proof_`.
  function isWhitelisted(address user_, bytes32[] memory proof_) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(user_));
    return proof_.verify(merkleRoot, leaf);
  }

  /**
   * @notice See {IERC721-tokenURI}.
   * @dev In order to make a metadata reveal, there must be an unrevealedURI string, which
   * gets set on the constructor and, for optimization purposes, when the owner sets a new
   * baseURI, the unrevealedURI gets deleted, saving gas and triggering a reveal.
   */
  function tokenURI(uint256 tokenId_) public view override returns (string memory) {
    require(_exists(tokenId_), "ERC721Metadata: query for nonexisting token");

    if (bytes(unrevealedURI).length > 0) return unrevealedURI;
    return string(abi.encodePacked(baseURI, tokenId_.toString(), baseExtension));
  }

  /// @notice Set baseURI to `baseURI_`, baseExtension to `baseExtension_` and deletes unrevealedURI, triggering a reveal.
  function setBaseURI(string memory baseURI_, string memory baseExtension_) external onlyOwner {
    baseURI = baseURI_;
    baseExtension = baseExtension_;
    delete unrevealedURI;
  }

  /// @notice Set unrevealedURI to `unrevealedURI_`.
  function setUnrevealedURI(string memory unrevealedURI_) external onlyOwner {
    unrevealedURI = unrevealedURI_;
  }

  /// @notice Set saleState to `saleState_`.
  function setSaleState(uint256 saleState_) external onlyOwner {
    saleState = saleState_;
  }

  /// @notice Set merkleRoot to `merkleRoot_`.
  function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
    merkleRoot = merkleRoot_;
  }

  /// @notice Set opensea to `opensea_`.
  function setOpensea(address opensea_) external onlyOwner {
    opensea = opensea_;
  }

  /// @notice Set looksrare to `looksrare_`.
  function setLooksrare(address looksrare_) external onlyOwner {
    looksrare = looksrare_;
  }

  /// @notice Toggle pre-approve feature state for sender.
  function toggleMarketplacesApproved() external onlyOwner {
    marketplacesApproved = !marketplacesApproved;
  }

  /// @notice Withdraw `amount_` of `token_` to the sender.
  function withdrawERC20(IERC20 token_, uint256 amount_) external onlyOwner {
    token_.transfer(msg.sender, amount_);
  }

  /// @notice Withdraw `tokenId_` of `token_` to the sender.
  function withdrawERC721(IERC721 token_, uint256 tokenId_) external onlyOwner {
    token_.safeTransferFrom(address(this), msg.sender, tokenId_);
  }

  /// @notice Withdraw `tokenId_` with amount of `value_` from `token_` to the sender.
  function withdrawERC1155(
    IERC1155 token_,
    uint256 tokenId_,
    uint256 value_
  ) external onlyOwner {
    token_.safeTransferFrom(address(this), msg.sender, tokenId_, value_, "");
  }

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
