// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPrincipalCollateralRecorder {
    function recordPrincipalCollateral(
        string memory name,
        uint256 amount0,
        uint256 amount1,
        uint256 amount2
    ) external;
}
