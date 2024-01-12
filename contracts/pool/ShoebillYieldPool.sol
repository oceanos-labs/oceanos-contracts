// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IShoebillERC20.sol";
import "./base/YieldPoolBase.sol";

contract ShoebillYieldPool is Initializable, YieldPoolBase {
    IShoebillERC20 public sbToken;

    function initialize(
        IOcUSD _ocUsd,
        IERC20 _collateral,
        IShoebillERC20 _sbToken
    ) external initializer {
        _initialize(_ocUsd, _collateral);

        sbToken = _sbToken;
    }

    function getAssetPrice() public view override returns (uint256) {
        return priceCalculator.priceOf(address(collateralAsset));
    }

    function _depositToYieldPool(uint256 amount) internal override {
        if (address(collateralAsset) == address(0)) {
            sbToken.mint{value: amount}();
        } else {
            collateralAsset.approve(address(sbToken), amount);
            sbToken.mint(amount);
        }
    }

    function _withdrawFromYieldPool(uint256 amount) internal override {
        sbToken.redeemUnderlying(amount);
    }

    function claimYield() external override {
        // TODO : claim yield
    }

    uint256[50] private __gap;
}
