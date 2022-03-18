// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Wrapper} from "../interfaces/IERC20Wrapper.sol";
import {IMasterChefV2} from "../interfaces/IMasterChefV2.sol";
import {FeeBase} from "./FeeBase.sol";

abstract contract WMasterChefV2 is FeeBase, ERC20, ReentrancyGuard, IERC20Wrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public pid;
  IMasterChefV2 public chef; // Sushiswap masterChef
  IERC20 public rewardToken; // reward token
  IERC20 public lpToken; // Sushi token

  uint256 private constant MAX_UINT256 = type(uint128).max;

  constructor(
    string memory _name,
    string memory _symbol,
    IMasterChefV2 _chef,
    uint256 _pid,
    address _lpToken,
    address _rewardToken,
    address _rewardDestination,
    uint256 _rewardFee,
    address _governance
  ) ERC20(_name, _symbol) {
    chef = _chef;

    lpToken = IERC20(_lpToken);
    rewardToken = IERC20(_rewardToken);
    pid = _pid;

    _setRewardFeeAddress(_rewardDestination);
    _setRewardFeeRate(_rewardFee);
    _transferOwnership(_governance);
  }

  /// @dev Mint ERC20 token
  /// @param amount Token amount to wrap
  function deposit(uint256 amount) external override nonReentrant returns (bool) {
    // take the LP tokens
    lpToken.safeTransferFrom(msg.sender, address(this), amount);

    // stake into the masterchef contract
    lpToken.safeIncreaseAllowance(address(chef), amount);
    chef.deposit(pid, amount, address(this));

    _mint(msg.sender, amount);
    return true;
  }

  /// @dev Burn ERC20 token to redeem LP ERC20 token back plus SUSHI rewards.
  /// @param amount Token amount to burn
  function withdraw(uint256 amount) external override nonReentrant returns (bool) {
    harvest();

    // calculate accumulated rewards
    uint256 userRewards = _accumulatedRewardsFor(msg.sender);
    uint256 bal = balanceOf(msg.sender);
    uint256 total = totalSupply();
    uint256 perc = bal.mul(1e18).div(total);
    uint256 rewardsToSend = userRewards.mul(perc).div(1e18);

    // withdraw and send the lp token back
    _burn(msg.sender, amount);
    chef.withdraw(pid, amount, msg.sender);

    // tax and send the earnings
    if (rewardsToSend > 0) _chargeFeeAndTransfer(rewardToken, rewardsToSend, msg.sender);
    return true;
  }

  function rewardTokenBalance() public view returns (uint256) {
    return rewardToken.balanceOf(address(this));
  }

  function harvest() public {
    chef.harvest(pid, address(this));
  }

  function _accumulatedRewards() internal view virtual returns (uint256) {
    // todo: implement this!
    return uint256(0);
  }

  function accumulatedRewards() external view override returns (uint256) {
    return _accumulatedRewards();
  }

  function accumulatedRewardsFor(address _user) external view override returns (uint256) {
    return _accumulatedRewardsFor(_user);
  }

  function _accumulatedRewardsFor(address _user) internal view returns (uint256) {
    uint256 accRewards = _accumulatedRewards();
    uint256 bal = balanceOf(_user);
    uint256 total = totalSupply();

    uint256 perc = bal.mul(1e18).div(total);
    return accRewards.mul(perc).div(1e18);
  }
}