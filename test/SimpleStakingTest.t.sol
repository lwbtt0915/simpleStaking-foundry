// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/SimpleStaking.sol";

/// @title Staking合约测试
contract SimpleStakingTest is Test {
    // 测试用的ERC20代币
    ERC20 public testToken;
    // Staking合约
    SimpleStaking public stakingContract;
    
    // 测试账户
    address public alice = address(0x1);
    address public bob = address(0x2);
    
    // 奖励率 (每秒每个代币奖励 0.1 个代币)
    uint256 public constant REWARD_RATE = 1e17;
    
    function setUp() public {
        // 部署测试代币
        testToken = new ERC20("Test Token", "TST");
        
        // 给测试账户 mint 代币
        testToken.mint(alice, 1000 ether);
        testToken.mint(bob, 1000 ether);
        
        // 部署Staking合约
        stakingContract = new SimpleStaking(address(testToken), REWARD_RATE);
        
        // 给Staking合约 mint 奖励代币
        testToken.mint(address(stakingContract), 10000 ether);
    }
    
    /// @notice 测试质押功能
    function testStake() public {
        uint256 stakeAmount = 100 ether;
        
        // 授权Staking合约花费代币
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        
        // 质押代币
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        // 验证状态
        assertEq(stakingContract.stakers(alice).amount, stakeAmount);
        assertEq(stakingContract.totalStaked(), stakeAmount);
        assertEq(testToken.balanceOf(alice), 900 ether);
        assertEq(testToken.balanceOf(address(stakingContract)), 10000 ether + stakeAmount);
    }
    
    /// @notice 测试奖励计算
    function testCalculateReward() public {
        uint256 stakeAmount = 100 ether;
        
        // Alice质押代币
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        // 快进时间 1小时 (3600秒)
        vm.warp(block.timestamp + 3600);
        
        // 计算预期奖励: 100 * 3600 * 0.1 = 36000 个代币 (18位小数)
        uint256 expectedReward = (stakeAmount * 3600 * REWARD_RATE) / 1e18;
        uint256 actualReward = stakingContract.calculateReward(alice);
        
        assertEq(actualReward, 3600 ether);
    }
    
    /// @notice 测试领取奖励
    function testClaimReward() public {
        uint256 stakeAmount = 100 ether;
        
        // Alice质押代币
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        // 快进时间 1小时
        vm.warp(block.timestamp + 3600);
        
        // 记录Alice的初始余额
        uint256 initialBalance = testToken.balanceOf(alice);
        
        // 领取奖励
        vm.prank(alice);
        stakingContract.claimReward();
        
        // 验证奖励到账
        uint256 expectedReward = 3600 ether;
        assertEq(testToken.balanceOf(alice), initialBalance + expectedReward);
    }
    
    /// @notice 测试提取质押
    function testUnstake() public {
        uint256 stakeAmount = 100 ether;
        
        // Alice质押代币
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        // 快进时间 1小时
        vm.warp(block.timestamp + 3600);
        
        // 提取质押
        vm.prank(alice);
        stakingContract.unstake(stakeAmount);
        
        // 验证状态
        assertEq(stakingContract.stakers(alice).amount, 0);
        assertEq(stakingContract.totalStaked(), 0);
        assertEq(testToken.balanceOf(alice), 900 ether); // 还没领取奖励
    }
    
    /// @notice 测试退出功能（提取+领取）
    function testExit() public {
        uint256 stakeAmount = 100 ether;
        
        // Alice质押代币
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        // 快进时间 1小时
        vm.warp(block.timestamp + 3600);
        
        // 记录初始余额
        uint256 initialBalance = testToken.balanceOf(alice);
        
        // 退出
        vm.prank(alice);
        stakingContract.exit();
        
        // 验证最终余额 (初始 + 质押本金 + 奖励)
        assertEq(testToken.balanceOf(alice), initialBalance + stakeAmount + 3600 ether);
    }
}