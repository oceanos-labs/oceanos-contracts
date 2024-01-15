// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./base/PoolBase.sol";
import "../interfaces/IPriceCalculator.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SimplePool is Initializable, PoolBase {
    function initialize(
        IOcUSD _ocUsd,
        IERC20 _collateral
    ) external initializer {
        _initialize(_ocUsd, _collateral);
    }

    function getAssetPrice() public view override returns (uint256) {
        return priceCalculator.priceOf(address(collateralAsset));
    }

    uint256[50] private __gap;
}
