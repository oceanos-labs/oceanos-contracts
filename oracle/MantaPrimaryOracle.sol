// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../interfaces/IPriceCalculator.sol";

contract MantaPrimaryOracle is IPriceCalculator {
    function priceOf(address asset) external view override returns (uint) {
        return 0;
    }
}
