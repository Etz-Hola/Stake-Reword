
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking", function() {
    let staking, stakingToken, rewardToken, owner, addr1;
    
    beforeEach(async function() {
        [owner, addr1] = await ethers.getSigners();
        
        // Deploy reward token
        const MyRewardToken = await ethers.getContractFactory("MyRewardToken");
        rewardToken = await MyRewardToken.deploy("My Reward Token", "MRT", ethers.utils.parseUnits("1000000", 18));
        await rewardToken.deployed();
        
        // Deploy mock staking token for testing
        const MockToken = await ethers.getContractFactory("MockERC20");
        stakingToken = await MockToken.deploy("Test Token", "TST", 18);
        await stakingToken.deployed();
        
        const Staking = await ethers.getContractFactory("Staking");
        staking = await Staking.deploy(stakingToken.address, rewardToken.address);
        await staking.deployed();
        
        // Mint tokens for testing
        await stakingToken.mint(owner.address, ethers.utils.parseUnits("10000", 18));
        await stakingToken.mint(addr1.address, ethers.utils.parseUnits("1000", 18));
    });
    
    it("Should stake tokens successfully", async function() {
        const amount = ethers.utils.parseUnits("100", 18);
        await stakingToken.connect(addr1).approve(staking.address, amount);
        await staking.connect(addr1).stake(amount);
        
        const stakeInfo = await staking.getStakeInfo(addr1.address);
        expect(stakeInfo.amount).to.equal(amount);
    });
});