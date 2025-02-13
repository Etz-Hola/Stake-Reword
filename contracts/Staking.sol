// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Custom errors for gas efficiency
error Staking__InsufficientBalance();
error Staking__InvalidAmount();
error Staking__NotEnoughStakeTime();
error Staking__InsufficientRewardBalance();

contract Staking is ReentrancyGuard, Ownable {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    
    // Staking parameters
    uint256 public constant MIN_STAKING_PERIOD = 7 days;
    uint256 public constant REWARD_RATE = 100; // 100 basis points (1%) per year
    
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 lastRewardCalculation;
    }
    
    mapping(address => StakeInfo) public stakes;
    
    // Track total staked amount
    uint256 public totalStaked;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event RewardsAdded(uint256 amount);
    
    constructor(address _stakingToken, address _rewardToken) Ownable() {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
    
    function stake(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert Staking__InvalidAmount();
        
        // Transfer staking tokens
        bool success = stakingToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert Staking__InsufficientBalance();
        
        // Track staked amount and duration
        StakeInfo storage userStake = stakes[msg.sender];
        if (userStake.amount > 0) {
            uint256 pendingReward = calculateReward(msg.sender);
            userStake.amount += _amount;
            userStake.lastRewardCalculation = block.timestamp;
        } else {
            userStake.amount = _amount;
            userStake.timestamp = block.timestamp;
            userStake.lastRewardCalculation = block.timestamp;
        }
        
        totalStaked += _amount;
        emit Staked(msg.sender, _amount);
    }
    
    function withdraw() external nonReentrant {
        StakeInfo storage userStake = stakes[msg.sender];
        if (userStake.amount == 0) revert Staking__InvalidAmount();
        
        if (block.timestamp < userStake.timestamp + MIN_STAKING_PERIOD) {
            revert Staking__NotEnoughStakeTime();
        }
        
        uint256 reward = calculateReward(msg.sender);
        uint256 stakeAmount = userStake.amount;
        
        // Check if contract has enough reward tokens
        if (rewardToken.balanceOf(address(this)) < reward) {
            revert Staking__InsufficientRewardBalance();
        }
        
        // Reset stake
        totalStaked -= userStake.amount;
        userStake.amount = 0;
        userStake.timestamp = 0;
        userStake.lastRewardCalculation = 0;
        
        // Transfer staking tokens back
        bool successStake = stakingToken.transfer(msg.sender, stakeAmount);
        if (!successStake) revert Staking__InsufficientBalance();
        
        // Transfer reward tokens
        bool successReward = rewardToken.transfer(msg.sender, reward);
        if (!successReward) revert Staking__InsufficientBalance();
        
        emit Withdrawn(msg.sender, stakeAmount, reward);
    }
    
    function calculateReward(address _user) public view returns (uint256) {
        StakeInfo memory userStake = stakes[_user];
        if (userStake.amount == 0) return 0;
        
        uint256 stakingDuration = block.timestamp - userStake.lastRewardCalculation;
        uint256 annualReward = (userStake.amount * REWARD_RATE) / 10000;
        uint256 reward = (annualReward * stakingDuration) / 365 days;
        
        return reward;
    }
    
    function addRewards(uint256 _amount) external onlyOwner {
        bool success = rewardToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert Staking__InsufficientBalance();
        emit RewardsAdded(_amount);
    }
    
    function getStakeInfo(address _user) external view returns (StakeInfo memory) {
        return stakes[_user];
    }
    
    function emergencyWithdrawRewardTokens(uint256 _amount) external onlyOwner {
        bool success = rewardToken.transfer(msg.sender, _amount);
        if (!success) revert Staking__InsufficientBalance();
    }
    
    function emergencyWithdrawStakeTokens(uint256 _amount) external onlyOwner {
        require(_amount <= stakingToken.balanceOf(address(this)) - totalStaked, "Amount exceeds available balance");
        bool success = stakingToken.transfer(msg.sender, _amount);
        if (!success) revert Staking__InsufficientBalance();
    }
}