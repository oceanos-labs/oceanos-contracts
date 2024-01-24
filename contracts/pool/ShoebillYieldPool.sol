// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IShoebillERC20.sol";
import "./base/YieldPoolBase.sol";

contract ShoebillYieldPool is Initializable, YieldPoolBase {
    IShoebillERC20 public sbToken;

    function initialize(
        IMintBurnERC20 _usdAsset,
        IERC20 _collateral,
        IShoebillERC20 _sbToken
    ) external initializer {
        _initialize(_usdAsset, _collateral);

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
        // 1. Claim yield from Supply yield
        uint256 includingIncreased = sbToken.balanceOfUnderlying(address(this));

        uint256 yield = includingIncreased - totalCollateralStored;

        // dust
        if (yield > 1000) {
            // withdraw from Supply yield
            sbToken.redeemUnderlying(yield - 1000);
            // transfer to feeReceiver
            _safeTransferOut(feeReceiver, yield - 1000);
        }
    }

    uint256[50] private __gap;
}
