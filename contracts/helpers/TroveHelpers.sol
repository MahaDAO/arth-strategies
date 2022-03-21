// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IBorrowerOperations} from "../interfaces/IBorrowerOperations.sol";
import {IFlashBorrower} from "../interfaces/IFlashBorrower.sol";
import {IFlashLoan} from "../interfaces/IFlashLoan.sol";
import {ILeverageStrategy} from "../interfaces/ILeverageStrategy.sol";
import {ITroveManager} from "../interfaces/ITroveManager.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LeverageAccount} from "../account/LeverageAccount.sol";

abstract contract TroveHelpers {
  using SafeMath for uint256;
  bytes4 private constant OPEN_LOAN_SELECTOR =
    bytes4(keccak256("openTrove(uint256,uint256,uint256,address,address,address)"));

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function openLoan(
    LeverageAccount acct,
    address borrowerOperations,
    uint256 maxFee,
    uint256 debt,
    uint256 collateralAmount,
    address upperHint,
    address lowerHint,
    address frontEndTag,
    IERC20 arth,
    IERC20 tokenB
  ) internal {
    bytes memory openLoanData = abi.encodeWithSelector(
      OPEN_LOAN_SELECTOR,
      maxFee,
      debt,
      collateralAmount,
      upperHint,
      lowerHint,
      frontEndTag
    );

    // approve spending
    approveTokenViaAccount(acct, tokenB, borrowerOperations, collateralAmount);

    // open loan using the user's proxy
    acct.callFn(borrowerOperations, openLoanData);

    // send the arth back to the flash loan contract to payback the flashloan
    uint256 arthBal = arth.balanceOf(address(acct));
    // require(false, uint2str(arthBal));

    if (arthBal > 0) transferTokenViaAccount(acct, arth, address(this), arthBal);
  }

  function closeLoan(
    LeverageAccount acct,
    address controller,
    address borrowerOperations,
    uint256 availableARTH,
    IERC20 arth,
    IERC20 wmatic
  ) internal {
    bytes memory closeLoanData = abi.encodeWithSignature("closeTrove()");

    // approve spending
    if (controller != address(0)) approveTokenViaAccount(acct, arth, controller, availableARTH);

    // close loan using the user's account
    acct.callFn(borrowerOperations, closeLoanData);

    // send the arth back to the flash loan contract to payback the flashloan
    uint256 arthBal = arth.balanceOf(address(acct));
    if (arthBal > 0) transferTokenViaAccount(acct, arth, address(this), arthBal);

    // send the collateral back to the flash loan contract to payback the flashloan
    uint256 collBal = wmatic.balanceOf(address(acct));
    if (collBal > 0) transferTokenViaAccount(acct, wmatic, address(this), collBal);
  }

  function transferTokenViaAccount(
    LeverageAccount acct,
    IERC20 token,
    address who,
    uint256 amount
  ) internal {
    // send tokens back to the contract
    bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", who, amount);
    acct.callFn(address(token), transferData);
  }

  function approveTokenViaAccount(
    LeverageAccount acct,
    IERC20 token,
    address who,
    uint256 amount
  ) internal {
    // send tokens back to the contract
    bytes memory transferData = abi.encodeWithSignature("approve(address,uint256)", who, amount);
    acct.callFn(address(token), transferData);
  }
}
