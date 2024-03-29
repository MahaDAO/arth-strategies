// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Wrapper} from "../interfaces/IERC20Wrapper.sol";
import {IStakingRewards} from "../interfaces/IStakingRewards.sol";
import {FeeBase} from "./FeeBase.sol";

abstract contract WStakingRewards is FeeBase, ERC20, ReentrancyGuard, IERC20Wrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IStakingRewards public staking; // Staking reward contract address
    IERC20 public underlying; // Underlying token address
    IERC20 public rewardToken; // Reward token address

    uint256 private constant MAX_UINT256 = type(uint128).max;

    address private me;

    constructor(
        string memory _name,
        string memory _symbol,
        address _staking,
        address _underlying,
        address _rewardToken,
        address _rewardDestination,
        uint256 _rewardFeeRate,
        address _governance
    ) ERC20(_name, _symbol) {
        staking = IStakingRewards(_staking);
        underlying = IERC20(_underlying);
        rewardToken = IERC20(_rewardToken);
        underlying.safeApprove(_staking, MAX_UINT256);

        _setRewardFeeAddress(_rewardDestination);
        _setRewardFeeRate(_rewardFeeRate);
        _transferOwnership(_governance);

        me = address(this);
    }

    function _depositFor(address account, uint256 amount) internal returns (bool) {
        underlying.safeTransferFrom(account, address(this), amount);
        staking.stake(amount);
        _mint(account, amount);
        return true;
    }

    function deposit(uint256 amount) external override nonReentrant returns (bool) {
        return _depositFor(msg.sender, amount);
    }

    function withdraw(uint256 amount) external override nonReentrant returns (bool) {
        harvest();

        // burn the stake and send back the underlying
        _burn(msg.sender, amount);
        staking.withdraw(amount);
        underlying.safeTransfer(msg.sender, amount);

        // send the earnings
        uint256 earnings = _accumulatedRewardsForAmount(amount);
        rewardToken.transfer(msg.sender, earnings);

        return true;
    }

    function harvest() public {
        uint256 balBefore = rewardToken.balanceOf(me);
        staking.getReward();
        uint256 earnings = rewardToken.balanceOf(me).sub(balBefore);
        _chargeFee(rewardToken, earnings);
    }

    function accumulatedRewards() external view virtual override returns (uint256) {
        return _accumulatedRewards();
    }

    function accumulatedRewardsFor(address _user) external view virtual override returns (uint256) {
        return _accumulatedRewardsFor(_user);
    }

    function _accumulatedRewardsFor(address _user) internal view returns (uint256) {
        uint256 bal = balanceOf(_user);
        return _accumulatedRewardsForAmount(bal);
    }

    function _accumulatedRewardsForAmount(uint256 bal) internal view returns (uint256) {
        uint256 accRewards = _accumulatedRewards();
        uint256 total = totalSupply();
        uint256 perc = bal.mul(1e18).div(total);
        return accRewards.mul(perc).div(1e18);
    }

    function _accumulatedRewards() internal view virtual returns (uint256) {
        return staking.earned(me).add(rewardToken.balanceOf(me));
    }
}
