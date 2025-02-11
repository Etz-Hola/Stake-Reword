// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Staking.sol";
import "./StakingReward.sol";

contract  Staking {
    IERC20 public s_stakingToken;    
    IERC20 public s_rewardToken;

    uint public constant REWARD_RATE=1e18; // uint public constant REWARD_RATE=10;
    uint private totalStakedTokens;
    uint public rewardPerTokenStored;
    uint public lastUpdateTime;

    mapping(address => uint) public stakedBalance;
    mapping(address => uint) public reword;

    event Staked(address indexed user, uint indexed amount);
    event Withdrawn(address indexed user, uint indexed amount);
     

    constructor(address _stakingToken, address _rewardToken) {
        s_stakingToken = IERC20(_stakingToken);
        s_rewardToken = IERC20(_rewardToken);

        function stake(uint amount) public {
            totalStakedTokens += amount;
            stakedBalance[msg.sender] += amount;
            s_stakingToken.transferFrom(msg.sender, address(this), amount);
            emit Staked(msg.sender, amount);
        }        

        function rewardPerTokenStored() view returns public(uint){
            if(totalStakedTokens==0){
                return rewardPerTokenStored;
            }
            uint rewardPerToken = rewardPerTokenStored + ((block.timestamp - lastUpdateTime) * REWARD_RATE * 1e18) / totalStakedTokens;
            return rewardPerTokenStored + ((block.timestamp - lastUpdateTime) * REWARD_RATE * 1e18) / totalStakedTokens;
        }

        function withdraw(uint amount) public {
            totalStakedTokens -= amount;
            stakedBalance[msg.sender] -= amount;
            s_stakingToken.transfer(msg.sender, amount);
            emit Withdrawn(msg.sender, amount);
        }

    }

}