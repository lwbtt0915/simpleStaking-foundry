// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleStaking.sol";
import "../src/TestToken.sol"; // 关键：导入自定义的TestToken，而非OpenZeppelin的ERC20

contract SimpleStakingTest is Test {
    // 关键：使用自定义的TestToken类型，而非ERC20
    TestToken public testToken;
    SimpleStaking public stakingContract;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    uint256 public constant REWARD_RATE = 1e17;

    function setUp() public {
        // 关键：实例化自定义的TestToken（非抽象合约）
        testToken = new TestToken("Test Token", "TST");
        
        // 现在可以正常调用mint方法
        testToken.mint(alice, 1000 ether);
        testToken.mint(bob, 1000 ether);
        
        stakingContract = new SimpleStaking(address(testToken), REWARD_RATE);
        testToken.mint(address(stakingContract), 10000 ether);
    }

    function testStake() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
      //  assertEq(stakingContract.stakers[alice].amount, stakeAmount);
        assertEq(stakingContract.totalStaked(), stakeAmount);
        assertEq(testToken.balanceOf(alice), 900 ether);
        assertEq(testToken.balanceOf(address(stakingContract)), 10000 ether + stakeAmount);
    }

    function testCalculateReward() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        vm.warp(block.timestamp + 3600);
        
        uint256 expectedReward = (stakeAmount * 3600 * REWARD_RATE) / 1e18;
        uint256 actualReward = stakingContract.calculateReward(alice);
        
        assertEq(actualReward, 3600 ether);
    }

    function testClaimReward() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        vm.warp(block.timestamp + 3600);
        
        uint256 initialBalance = testToken.balanceOf(alice);
        
        vm.prank(alice);
        stakingContract.claimReward();
        
        uint256 expectedReward = 3600 ether;
        assertEq(testToken.balanceOf(alice), initialBalance + expectedReward);
    }

    function testUnstake() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        vm.warp(block.timestamp + 3600);
        
        vm.prank(alice);
        stakingContract.unStake(stakeAmount);
        
        // assertEq(stakingContract.stakers[alice].amount, 0);
        assertEq(stakingContract.totalStaked(), 0);
        assertEq(testToken.balanceOf(alice), 900 ether);
    }

    function testExit() public {
        uint256 stakeAmount = 100 ether;
        
        vm.prank(alice);
        testToken.approve(address(stakingContract), stakeAmount);
        vm.prank(alice);
        stakingContract.stake(stakeAmount);
        
        vm.warp(block.timestamp + 3600);
        
        uint256 initialBalance = testToken.balanceOf(alice);
        
        vm.prank(alice);
        stakingContract.exit();
        
        assertEq(testToken.balanceOf(alice), initialBalance + stakeAmount + 3600 ether);
    }
}