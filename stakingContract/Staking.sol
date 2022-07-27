// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IToken1.sol";
import "./IToken2.sol";

contract Staking is Ownable{
    
    using SafeMath for uint256;
    
    uint256[] private tiersValue; 
    uint256[] private tiersRewards; 
    uint256 public currentTier = 0;
    uint256 private interval = 120;
    
    string[] private tierNames;
    
    Token1 public stakingToken;
    Token2 public rewardToken;
    
    struct User{
        uint256 stakeTime;
        uint256 lastCollectTime;
    }
    
    mapping (address => mapping (uint256 => User)) private userDetail;
    
    event stake(address _beneficiary, uint256 _amount, uint256 tier);
    event unstake(address _beneficiary, uint256 _amount, uint256 tier);
    event rewardCollect(address _beneficiary, uint256 _amount, uint256 tier);
    
    /**
     * @dev Sets the address of staking and reward token.
     *
     * All two of these values are mutable and they can only be modified
     */
    constructor (address _stakingToken, address _rewardToken) 
    {
        setTierAndRewardValue(1000_000000000000000000,2000_000000000000000000,"Bronze");
        setTierAndRewardValue(2000_000000000000000000,4000_000000000000000000,"Silver");
        setTierAndRewardValue(5000_000000000000000000,10000_000000000000000000,"Gold"); 
        setTierAndRewardValue(10000_000000000000000000,20000_000000000000000000,"Platinum");
        
        stakingToken = Token1(_stakingToken);
        rewardToken = Token2(_rewardToken);
    } 
    
    /**
    * @dev stakeToken to stake tokens on the platform.
    * @param _tier uint256 is the tier user wants to stake in.
    */
    function stakeToken(uint256 _tier) external {
        
        require(_tier < currentTier,"Invalid tier");
        
        userDetail[msg.sender][_tier].stakeTime = block.timestamp;
        userDetail[msg.sender][_tier].lastCollectTime = block.timestamp;
        
        stakingToken.transferFrom(msg.sender,address(this),tiersValue[_tier]); 
        
        emit stake(msg.sender,tiersValue[_tier],_tier);
    }
    
    /**
    * @dev unStakeToken to unstake tokens from the platform.
    * @param _tier uint256 is the tier user wants to unstake from.
    */
    function unStakeToken(uint256 _tier) external {
        
        require(userDetail[msg.sender][_tier].stakeTime > 0,"Not staked in this tier!");
        
        require(_tier < currentTier,"Invalid tier");
        
        collectReward(_tier);
        
        userDetail[msg.sender][_tier].stakeTime = 0;
        userDetail[msg.sender][_tier].lastCollectTime = 0;
        
        stakingToken.transfer(msg.sender,tiersValue[_tier]);
    
        emit unstake(msg.sender,tiersValue[_tier],_tier);    
    }
    
    /**
    * @dev collectAPYReward to collect user staking reward.
    * @param _tier uint256 is the tier user wants to collect reward from.
    */
    function collectReward(uint256 _tier) public {
        
        require(userDetail[msg.sender][_tier].stakeTime > 0,"Not staked in this tier!");
        
        require(block.timestamp >= userDetail[msg.sender][_tier].lastCollectTime.add(interval),"Please wait for duration to complete!");
        
        (uint256 rewardAmount,,uint256 totalStakeDays) = calculatedAPYForDays(msg.sender,_tier);
        
        userDetail[msg.sender][_tier].lastCollectTime = userDetail[msg.sender][_tier].stakeTime.add(interval.mul(totalStakeDays));
        
        rewardToken.mintReward(rewardAmount,msg.sender);
        
        emit rewardCollect(msg.sender,tiersValue[_tier],_tier);
        
    }
    
    /**
    * @dev calculatedAPYForDays to calculate reward of a user from a specific tier.
    * @param _beneficiary address of user who's reward is to be collected.
    * @param _tier uint256 is the tier from which users reward is to be collected.
    */
    function calculatedAPYForDays(address _beneficiary,uint256 _tier) public view returns(uint256 _reward,uint256 _interval,uint256 _totalStakeInterval){
        if(userDetail[_beneficiary][_tier].lastCollectTime > 0){
            _totalStakeInterval = (block.timestamp.sub(userDetail[_beneficiary][_tier].stakeTime)).div(interval);
            _interval = (block.timestamp.sub(userDetail[_beneficiary][_tier].lastCollectTime)).div(interval);
            _reward = _interval.mul(tiersRewards[_tier]);
        }
        else{
            _interval = 0;
            _reward = 0;
        }
    }
    
    /**
    * @dev setRewardToken to set address of reward token.
    * @param _rewardToken address of token which is to be given as reward for staking.
    */
    function setRewardToken(address _rewardToken) public onlyOwner{
        require( _rewardToken != address(0),"Token1! Invalid Address!");
        
        rewardToken = Token2(_rewardToken);
    }
    
    /**
    * @dev setStakeToken to set address of reward token.
    * @param _stakingToken address of token which is to be staked.
    */
    function setStakeToken(address _stakingToken) public onlyOwner{
        require( _stakingToken != address(0),"Token1! Invalid Address!");
        
        stakingToken = Token1(_stakingToken);
    }
    
    /**
    * @dev setTierAndRewardValue to add new tier in the system.
    * @param _tierValue uint256 amount required to stake in respective tier
    * @param _reward  uint256 amount of reward the user receive after specified interval
    * @param _name list of ids to be transferred
    */
    function setTierAndRewardValue(uint256 _tierValue, uint256 _reward, string memory _name) public onlyOwner{
        tiersValue.push(_tierValue);
        tiersRewards.push(_reward);
        tierNames.push(_name);
        currentTier++;
    }
    
    /**
    * @dev Returns tier stake value, reward token value and name of tier.
    * @param _tier uint256 ID of tier who's details are to be provided.
    */
    function getTierDetails(uint256 _tier) public view returns(uint256 _tierValue, uint256 _rewardValue, string memory _tierName){
        _tierName = tierNames[_tier];
        _tierValue = tiersValue[_tier];
        _rewardValue = tiersRewards[_tier];
    }
    
    /**
    * @dev Returns tier stake time and its last reward collect time.
    * @param _beneficiary address of user who's details are to be seen.
    * @param _tier uint256 ID of tier who's details are to be provided.
    */
    function getUserDetails(address _beneficiary, uint256 _tier) public view returns(uint256 _stakingTime, uint256 _lastRewardCollectTime){
        _stakingTime = userDetail[_beneficiary][_tier].stakeTime;
        _lastRewardCollectTime = userDetail[_beneficiary][_tier].lastCollectTime;
    }
}