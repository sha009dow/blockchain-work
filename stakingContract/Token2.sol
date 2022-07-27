// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 

contract Token2 is ERC20PresetMinterPauser, Ownable{
    
    
    address internal baseToken;
    
    modifier onlyRewarder() {
        require(baseToken == _msgSender(), "Token2: caller is not the baseToken");
        _;
    }
    
    constructor(string memory _name, string memory _symbol) 
    ERC20PresetMinterPauser(_name,_symbol)
    {
        
    } 
    
    function mintReward(uint256 _amount, address _beneficiary) public onlyRewarder{
        require( _amount > 0,"Token2! Invalid Amount!");
        
        require( _beneficiary != address(0),"Token2! Invalid Address!");
        
        _mint(_beneficiary,_amount);
    }
    
    function setRewarder(address _baseToken) public onlyOwner{
        require( _baseToken != address(0),"Token2! Invalid Address!");
        
        baseToken = _baseToken;
    }
}