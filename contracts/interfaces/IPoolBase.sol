// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "./IOcUSD.sol";

interface IPoolBase {
    function ocUsd() external view returns (IOcUSD);

    function poolIssuedOcUSD() external view returns (uint256);

    function totalCollateralAmount() external view returns (uint256);

    function getAsset() external view returns (address);

    function getAssetPrice() external view returns (uint256);

    function collateralAmount(address account) external view returns (uint256);

    function borrowedAmount(address account) external view returns (uint256);

    function collateralRatio(address account) external view returns (uint256);
}
