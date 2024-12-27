// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract EasyNFT is ERC721Enumerable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    error EasyNFT__NotOnWhitelistForAdvancedNFT();
    error EasyNFT__AlreadyMintedAnAdvancedNFT();
    error EasyNFT__MaxAdvancedNFTsMinted();
    error EasyNFT__NotOnWhitelistForNormalNFT();
    error EasyNFT__AlreadyMintedAnNormalNFT();
    error EasyNFT__MaxNormalNFTsMinted();
    error EasyNFT__MintPeriodNotOver();

    uint256 public constant MAX_ADVANCED = 4500; // 高级NFT最大数量
    uint256 public constant MAX_NORMAL = 500; // 普通NFT最大数量
    uint256 public advancedMinted = 0; // 已mint的高级NFT数量
    uint256 public normalMinted = 0; // 已mint的普通NFT数量

    uint256 public endTimestamp; // 活动结束时间（UNIX时间戳）

    // 白名单映射，记录每个地址的NFT类型
    mapping(address => bool) public whitelistAdvanced;
    mapping(address => bool) public whitelistNormal;

    // 每个地址的mint数量限制
    mapping(address => bool) public hasMintedAdvanced;
    mapping(address => bool) public hasMintedNormal;

    // 构造函数
    constructor() ERC721("EasyNFT", "EASY") Ownable(msg.sender) {}

    // 设置活动结束时间
    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        endTimestamp = _endTimestamp;
    }

    // 设置白名单（外部调用）
    function addToWhitelist(
        address[] calldata addresses,
        bool isAdvanced
    ) external onlyOwner {
        if (isAdvanced) {
            for (uint i = 0; i < addresses.length; i++) {
                whitelistAdvanced[addresses[i]] = true;
            }
        } else {
            for (uint i = 0; i < addresses.length; i++) {
                whitelistNormal[addresses[i]] = true;
            }
        }
    }

    // Mint高级Pass卡
    function mintAdvanced() external {
        if (!whitelistAdvanced[msg.sender]) {
            revert EasyNFT__NotOnWhitelistForAdvancedNFT();
        }
        if (hasMintedAdvanced[msg.sender]) {
            revert EasyNFT__AlreadyMintedAnAdvancedNFT();
        }
        if (advancedMinted >= MAX_ADVANCED) {
            revert EasyNFT__MaxAdvancedNFTsMinted();
        }

        hasMintedAdvanced[msg.sender] = true;
        advancedMinted++;

        _safeMint(msg.sender, advancedMinted); // mint NFT
    }

    // Mint普通Pass卡
    function mintNormal() external {
        if (!whitelistNormal[msg.sender]) {
            revert EasyNFT__NotOnWhitelistForNormalNFT();
        }
        if (hasMintedNormal[msg.sender]) {
            revert EasyNFT__AlreadyMintedAnNormalNFT();
        }
        if (normalMinted >= MAX_NORMAL) {
            revert EasyNFT__MaxNormalNFTsMinted();
        }

        hasMintedNormal[msg.sender] = true;
        normalMinted++;

        _safeMint(msg.sender, MAX_ADVANCED + normalMinted); // mint NFT
    }

    // Burn剩余的NFT
    function burnRemainingNFTs() external onlyOwner {
        if (block.timestamp <= endTimestamp) {
            revert EasyNFT__MintPeriodNotOver();
        }

        // Burn剩余的高级NFT
        uint256 remainingAdvanced = MAX_ADVANCED - advancedMinted;
        for (uint i = 1; i <= remainingAdvanced; i++) {
            _burn(advancedMinted + i);
        }

        // Burn剩余的普通NFT
        uint256 remainingNormal = MAX_NORMAL - normalMinted;
        for (uint i = 1; i <= remainingNormal; i++) {
            _burn(MAX_ADVANCED + normalMinted + i);
        }
    }

    // 设置NFT是否可以转移（根据需要设置）
    function setTransferability(bool isTransferable) external onlyOwner {
        if (isTransferable) {
            _setTransferable(true);
        } else {
            _setTransferable(false);
        }
    }

    // 关闭转移功能（这里可以根据需要修改）
    function _setTransferable(bool canTransfer) internal {
        // 实现逻辑，这里假设为可转移。
    }
}
