// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleStaking is Ownable {
    //质押代币合约地址
    IERC20 public immutable stakingToken;
    //每秒钟每个代币的奖励数量（精度：18位小数）
    uint256 public rewardRate;

    struct StakerInfo {
        uint256 amount; //质押数量
        uint256 rewardDebt; // 奖励债务
        uint256 lastUpdateTime;  // 最后更新事件
    }

    // 地址 =》 质押信息
    mapping(address => StakerInfo) public stakers;

    // 总质押数量
    uint256 public totalStaked;


     /// @notice 构造函数
    /// @param _stakingToken 质押代币地址
    /// @param _rewardRate 每秒奖励率 (例如: 1e18 表示每秒每个代币奖励1个代币)
    constructor(address _stakingToken, uint256 _rewardRate) Ownable(msg.sender) {
        require(_stakingToken != address(0), "Invalid token address");
        require(_rewardRate > 0, "Reward rate must be positive");
        
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
    }


    //  质押代币事件
    event Staked(address indexed user, uint256 amount);
    // 提出质押的代币事件
    event UnStaked(address indexed user, uint256 amount);
    // 领取奖励 事件
    event RewardClaimed(address indexed user, uint256 reward);
    // 更新奖励率事件
    event RewardRateUpdated(uint256 newRate);

    
    // 计算用户可以领取的奖励
    // @param user 用户地址
    // @return 可领取奖励数量 
    function calculateReward(address user) public view returns(uint256) {
        StakerInfo memory info = stakers[user];

        if(info.amount == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - info.lastUpdateTime;
        return (info.amount * timeElapsed * rewardRate);
    }  




   
    /// @notice 更新用户奖励状态
    /// @param user 用户地址
    /// @dev 内部函数，修改状态前调用
    function updateReward(address user) internal {
        StakerInfo storage info = stakers[user];
        if (info.amount > 0) {
            uint256 reward = calculateReward(user);
            info.rewardDebt += reward;
        }

        info.lastUpdateTime = block.timestamp;
    } 



     /// @notice 质押代币
    /// @param amount 质押数量
    function stake(uint256 amount) external  {
        require(amount >0, "Amount must be positive");
     
        // 更新奖励状态
        updateReward(msg.sender);

       bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
       require(success, "Transfer failed");

       //更新质押信息
       StakerInfo storage info = stakers[msg.sender];
       info.amount += amount;
       totalStaked += amount;

       emit Staked(msg.sender, amount);
    }




    // 提出质押的代币
    // @param amount 提出的数量
    function unStake(uint256 amount) public  {
        require(amount > 0, "Amount must be positive");

        StakerInfo storage info = stakers[msg.sender];
        require(info.amount >= amount, "INsufficient staked amount");

        //更新奖励
        updateReward(msg.sender);

        info.amount -= amount;
        totalStaked -= amount;

        // 转移代币给用户
        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "transfer failed.");

        emit UnStaked(msg.sender, amount);
    }


    // 领取奖励
    function claimReward() public {
       // 更新奖励状态
       updateReward(msg.sender); 

       StakerInfo storage info = stakers[msg.sender];
       uint256 reward = info.rewardDebt;
       require(reward > 0, "No reward to claim");

        // 重置奖励债务
        info.rewardDebt = 0;

          // 转移奖励给用户
        bool success = stakingToken.transfer(msg.sender, reward);
        require(success, "Reward transfer failed");
        
        emit RewardClaimed(msg.sender, reward);   
    }


    //提取全部质押并领取奖励  
    function exit() external {
    // 提取质押的代币
       unStake(stakers[msg.sender].amount);
    //    领取奖励
       claimReward();
    }



     /// @notice 管理员更新奖励率
    /// @param newRate 新的奖励率
    function setRewardRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Reward rate must be positive");
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }
    
    /// @notice 紧急提取合约中的代币（仅管理员）
    /// @dev 应急功能，谨慎使用
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be positive");
        
        IERC20(token).transfer(owner(), amount);
    }



}