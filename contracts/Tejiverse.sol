// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "sol-temple/src/utils/Proxy.sol";
import "sol-temple/src/utils/Upgradable.sol";
import "sol-temple/src/tokens/ERC721Upgradable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Tejiverse
 * @author naomsa <https://twitter.com/naomsa666>
 * @author Teji <https://twitter.com/0xTeji>
 */
contract Tejiverse is Upgradable, ERC721Upgradable {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  /// @notice Max supply.
  uint256 public constant TEJI_MAX = 1000;
  /// @notice Max amount per claim.
  uint256 public constant TEJI_PER_TX = 3;

  /// @notice Unrevealed metadata URI.
  string public unrevealedURI;
  /// @notice Metadata base URI.
  string public baseURI;
  /// @notice Metadata base file extension.
  string public baseExtension;

  /// @notice OpenSea proxy registry.
  address public opensea;
  /// @notice LooksRare marketplace transfer manager.
  address public looksrare;
  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved = true;

  /// @notice 0 = CLOSED, 1 = WHITELIST, 2 = PUBLIC.
  uint256 public saleState;

  /// @notice Whitelist merkle root.
  bytes32 public merkleRoot;
  /// @notice Whitelist mints per address.
  mapping(address => uint256) public whitelistMinted;

  function initialize(string memory newUnrevealedURI, bytes32 newMerkleRoot) external onlyOwner {
    __ERC721_init("Tejiverse", "TEJI");

    unrevealedURI = newUnrevealedURI;
    merkleRoot = newMerkleRoot;
    opensea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    looksrare = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
  }

  /// @notice Claim one or more tokens.
  function claim(uint256 amount) external {
    uint256 supply = totalSupply;
    require(supply + amount <= TEJI_MAX, "Max supply exceeded");
    if (msg.sender != owner) {
      require(saleState == 2, "Public sale is not open");
      require(amount > 0 && amount <= TEJI_PER_TX, "Invalid claim amount");
    }

    for (uint256 i = 0; i < amount; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice Claim one or more tokens for whitelisted user.
  function claimWhitelist(uint256 amount, bytes32[] memory proof_) external {
    uint256 supply = totalSupply;
    require(supply + amount <= TEJI_MAX, "Max supply exceeded");
    if (msg.sender != owner) {
      require(saleState == 1, "Whitelist sale is not open");
      require(amount > 0 && amount + whitelistMinted[msg.sender] <= TEJI_PER_TX, "Invalid claim amount");
      require(isWhitelisted(msg.sender, proof_), "Invalid proof");
    }

    whitelistMinted[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice Retrieve if `user_` is whitelisted based on his `proof_`.
  function isWhitelisted(address user_, bytes32[] memory proof_) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(user_));
    return proof_.verify(merkleRoot, leaf);
  }

  /// @notice See {IERC721-tokenURI}.
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "ERC721Metadata: query for nonexisting token");

    if (bytes(unrevealedURI).length > 0) return unrevealedURI;
    return string(abi.encodePacked(baseURI, id.toString(), baseExtension));
  }

  /// @notice Set unrevealedURI to `newUnrevealedURI`.
  function setUnrevealedURI(string memory newUnrevealedURI) external onlyOwner {
    unrevealedURI = newUnrevealedURI;
  }

  /// @notice Set baseURI to `newBaseURI`.
  function setBaseURI(string memory newBaseURI, string memory newBaseExtension) external onlyOwner {
    baseURI = newBaseURI;
    baseExtension = newBaseExtension;
    delete unrevealedURI;
  }

  /// @notice Set saleState to `newSaleState`.
  function setSaleState(uint256 newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice Set merkleRoot to `newMerkleRoot`.
  function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
    merkleRoot = newMerkleRoot;
  }

  /// @notice Set opensea to `newOpensea`.
  function setOpensea(address newOpensea) external onlyOwner {
    opensea = newOpensea;
  }

  /// @notice Set looksrare to `newLooksrare`.
  function setLooksrare(address newLooksrare) external onlyOwner {
    looksrare = newLooksrare;
  }

  /// @notice Toggle pre-approve feature state for sender.
  function toggleMarketplacesApproved() external onlyOwner {
    marketplacesApproved = !marketplacesApproved;
  }

  /// @notice Withdraw `value` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 value) external onlyOwner {
    token.transfer(msg.sender, value);
  }

  /// @notice Withdraw `id` of `token` to the sender.
  function withdrawERC721(IERC721 token, uint256 id) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, id);
  }

  /// @notice Withdraw `id` with `value` from `token` to the sender.
  function withdrawERC1155(
    IERC1155 token,
    uint256 id,
    uint256 value
  ) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, id, value, "");
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
