// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Token1{
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool); 
}