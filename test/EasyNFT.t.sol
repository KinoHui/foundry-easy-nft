// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EasyNFT.sol";

contract EasyNFTTest is Test {
    EasyNFT private nft;
    address private owner;
    address private user1;
    address private user2;
    address private user3;
    address[] public advancedAddresses;
    address[] public normalAddresses;

    uint256 private constant ADVANCED_MINT_COST = 1 ether; // 随便设定的mint费用
    uint256 private constant NORMAL_MINT_COST = 1 ether;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);

        nft = new EasyNFT(); // 部署新的NFT合约实例
    }

    // 测试设置和获取活动结束时间
    function testSetEndTimestamp() public {
        uint256 timestamp = block.timestamp + 1 days; // 设置为1天后
        nft.setEndTimestamp(timestamp);
        assertEq(nft.endTimestamp(), timestamp);
    }

    // 测试添加白名单
    function testAddToWhitelist() public {
        advancedAddresses.push(user1);
        advancedAddresses.push(user2);

        nft.addToWhitelist(advancedAddresses, true); // 将 user1 和 user2 加入高级白名单

        assertTrue(nft.whitelistAdvanced(user1));
        assertTrue(nft.whitelistAdvanced(user2));
        assertFalse(nft.whitelistAdvanced(user3)); // user3 不在白名单中
    }

    // 测试高级NFT的mint
    function testMintAdvanced() public {
        advancedAddresses.push(user1);

        nft.addToWhitelist(advancedAddresses, true); // 将 user1 加入高级白名单

        vm.prank(user1); // 切换到 user1
        nft.mintAdvanced();

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.ownerOf(1), user1);
    }

    // 测试普通NFT的mint
    function testMintNormal() public {
        normalAddresses.push(user2);

        nft.addToWhitelist(normalAddresses, false); // 将 user2 加入普通白名单

        vm.prank(user2); // 切换到 user2
        nft.mintNormal();

        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.ownerOf(4501), user2); // 普通NFT的ID应该从 5001 开始
    }

    // 测试超过mint限制时抛出错误
    function testExceedAdvancedMintLimit() public {
        advancedAddresses.push(user1);

        nft.addToWhitelist(advancedAddresses, true); // 将 user1 加入高级白名单

        vm.prank(user1);
        nft.mintAdvanced();

        vm.prank(user1);
        vm.expectRevert(EasyNFT.EasyNFT__AlreadyMintedAnAdvancedNFT.selector);
        nft.mintAdvanced(); // user1 已经mint了一个高级NFT，再次mint应该失败
    }

    // 测试烧毁未mint的NFT
    function testBurnRemainingNFTs() public {
        advancedAddresses.push(user1);
        advancedAddresses.push(user2);
        normalAddresses.push(user3);
        normalAddresses.push(owner);

        nft.addToWhitelist(advancedAddresses, true); // 加入高级白名单
        nft.addToWhitelist(normalAddresses, false); // 加入普通白名单

        vm.prank(user1);
        nft.mintAdvanced();

        nft.setEndTimestamp(block.timestamp - 1); // 设置活动已经结束

        vm.prank(owner); // 切换到合约所有者
        nft.burnRemainingNFTs(); // 调用烧毁未mint的NFT

        assertEq(nft.totalSupply(), 0); // 所有未mint的NFT应当被烧毁
    }

    // 测试活动未结束时烧毁未mint的NFT会抛出错误
    function testBurnRemainingNFTsNotOver() public {
        advancedAddresses.push(user1);

        nft.addToWhitelist(advancedAddresses, true); // 将 user1 加入高级白名单

        nft.setEndTimestamp(block.timestamp + 1 days); // 设置活动结束时间为未来的时间

        vm.expectRevert(EasyNFT.EasyNFT__MintPeriodNotOver.selector);
        nft.burnRemainingNFTs(); // 活动未结束时烧毁NFT应该失败
    }
}
