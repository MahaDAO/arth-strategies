// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingRewards {
    function rewardPerToken() external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function earned(address who) external view returns (uint256);

    function getReward() external;
}
