// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Token2{
    function mintReward(uint256 _amount, address _beneficiary) external;
}