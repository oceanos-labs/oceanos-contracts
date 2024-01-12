// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IShoebillERC20 {
    // for cerc20
    function mint(uint256) external returns (uint256);

    // for cether
    function mint() external payable returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function comptroller() external view returns (address);
}

interface IComtroller {
    function claimComp(address holder) external;
}
