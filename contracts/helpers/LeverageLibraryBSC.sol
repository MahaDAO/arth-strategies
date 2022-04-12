// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IStableSwapRouter} from "../interfaces/IStableSwapRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {ITroveManager} from "../interfaces/ITroveManager.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";

import {IERC20Wrapper} from "../interfaces/IERC20Wrapper.sol";
import {LeverageAccount, LeverageAccountRegistry} from "../account/LeverageAccountRegistry.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LeverageLibraryBSC {
  using SafeMath for uint256;

  function getAccount(LeverageAccountRegistry accountRegistry, address who)
    public
    view
    returns (LeverageAccount)
  {
    return accountRegistry.accounts(who);
  }

  function getTroveCR(
    IPriceFeed priceFeed,
    ITroveManager troveManager,
    address who
  ) public view returns (uint256) {
    uint256 price = priceFeed.fetchPrice();
    uint256 debt = troveManager.getTroveDebt(who);
    uint256 coll = troveManager.getTroveColl(who);
    return coll.mul(price).div(debt);
  }

  function rewardsEarned(
    LeverageAccountRegistry accountRegistry,
    ITroveManager troveManager,
    IERC20Wrapper stakingWrapper,
    address who
  ) public view returns (uint256) {
    address acct = address(getAccount(accountRegistry, who));
    uint256 collat = troveManager.getTroveColl(acct);

    uint256 accRewards = stakingWrapper.accumulatedRewards();
    uint256 total = stakingWrapper.totalSupply();
    uint256 perc = collat.mul(1e18).div(total);
    return accRewards.mul(perc).div(1e18);
  }

  function underlyingCollateralFromBalance(uint256 balance, address lp)
    public
    view
    returns (uint256[2] memory)
  {
    IUniswapV2Pair pair = IUniswapV2Pair(lp);

    IERC20 token0 = IERC20(pair.token0());
    IERC20 token1 = IERC20(pair.token1());

    uint256 total = pair.totalSupply();
    uint256 perc = balance.mul(1e18).div(total);

    return [token0.balanceOf(lp).mul(perc).div(1e18), token1.balanceOf(lp).mul(perc).div(1e18)];
  }

  function swapExcessARTH(
    address me,
    address to,
    int128 tokenId, // 1 -> busd, 2 -> usdc, 3 -> usdt
    IStableSwapRouter ellipsis,
    IERC20 arth
  ) public {
    if (arth.balanceOf(me) > 0) {
      arth.approve(address(ellipsis), arth.balanceOf(me));
      ellipsis.sellARTHforToken(tokenId, arth.balanceOf(me), to, block.timestamp);
    }
  }
}
