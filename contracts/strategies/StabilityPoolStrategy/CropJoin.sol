// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import {IERC20WithDecimals} from "../../interfaces/IERC20WithDecimals.sol";

interface VatLike {
    function urns(bytes32, address) external view returns (uint256, uint256);

    function gem(bytes32, address) external view returns (uint256);

    function slip(
        bytes32,
        address,
        int256
    ) external;
}

// receives tokens and shares them among holders
contract CropJoin {
    VatLike public immutable vat; // cdp engine
    bytes32 public immutable ilk; // collateral type
    IERC20WithDecimals public immutable gem; // collateral token
    uint256 public immutable dec; // gem decimals
    IERC20WithDecimals public immutable bonus; // rewards token

    uint256 public share; // crops per gem    [ray]
    uint256 public total; // total gems       [wad]
    uint256 public stock; // crop balance     [wad]

    mapping(address => uint256) public crops; // crops per user  [wad]
    mapping(address => uint256) public stake; // gems per user   [wad]

    uint256 internal immutable to18ConversionFactor;
    uint256 internal immutable toGemConversionFactor;

    // --- Events ---
    event Join(uint256 val);
    event Exit(uint256 val);
    event Flee();
    event Tack(address indexed src, address indexed dst, uint256 wad);

    constructor(
        address vat_,
        bytes32 ilk_,
        address gem_,
        address bonus_
    ) {
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = IERC20WithDecimals(gem_);
        uint256 dec_ = IERC20WithDecimals(gem_).decimals();
        require(dec_ <= 18);
        dec = dec_;
        to18ConversionFactor = 10**(18 - dec_);
        toGemConversionFactor = 10**dec_;

        bonus = IERC20WithDecimals(bonus_);
    }

    function add(uint256 x, uint256 y) public pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) public pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) public pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(x, sub(y, 1)) / y;
    }

    uint256 constant WAD = 10**18;

    function wmul(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = mul(x, y) / WAD;
    }

    function wdiv(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = mul(x, WAD) / y;
    }

    function wdivup(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = divup(mul(x, WAD), y);
    }

    uint256 public constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }

    function rmulup(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = divup(mul(x, y), RAY);
    }

    function rdiv(uint256 x, uint256 y) public pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }

    // Net Asset Valuation [wad]
    function nav() public virtual returns (uint256) {
        uint256 _nav = gem.balanceOf(address(this));
        return mul(_nav, to18ConversionFactor);
    }

    // Net Assets per Share [wad]
    function nps() public returns (uint256) {
        if (total == 0) return WAD;
        else return wdiv(nav(), total);
    }

    function crop() internal virtual returns (uint256) {
        return sub(bonus.balanceOf(address(this)), stock);
    }

    function harvest(address from, address to) internal {
        if (total > 0) share = add(share, rdiv(crop(), total));

        uint256 last = crops[from];
        uint256 curr = rmul(stake[from], share);
        if (curr > last) require(bonus.transfer(to, curr - last));
        stock = bonus.balanceOf(address(this));
    }

    function join(address urn, uint256 val) internal virtual {
        harvest(urn, urn);
        if (val > 0) {
            uint256 wad = wdiv(mul(val, to18ConversionFactor), nps());

            // Overflow check for int256(wad) cast below
            // Also enforces a non-zero wad
            require(int256(wad) > 0);

            require(gem.transferFrom(msg.sender, address(this), val));
            vat.slip(ilk, urn, int256(wad));

            total = add(total, wad);
            stake[urn] = add(stake[urn], wad);
        }
        crops[urn] = rmulup(stake[urn], share);
        emit Join(val);
    }

    function exit(address guy, uint256 val) internal virtual {
        harvest(msg.sender, guy);
        if (val > 0) {
            uint256 wad = wdivup(mul(val, to18ConversionFactor), nps());

            // Overflow check for int256(wad) cast below
            // Also enforces a non-zero wad
            require(int256(wad) > 0);

            require(gem.transfer(guy, val));
            vat.slip(ilk, msg.sender, -int256(wad));

            total = sub(total, wad);
            stake[msg.sender] = sub(stake[msg.sender], wad);
        }
        crops[msg.sender] = rmulup(stake[msg.sender], share);
        emit Exit(val);
    }
}
