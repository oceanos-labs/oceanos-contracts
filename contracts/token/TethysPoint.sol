// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TethysPoint is ERC20 {
    address dev;

    constructor() ERC20("Tethys Point", "TP") {
        dev = msg.sender;
    }

    function devMint(address _to, uint256 _amount) external {
        require(msg.sender == dev, "dev: wut?");
        _mint(_to, _amount);
    }

    function devBurn(address _from, uint256 _amount) external {
        require(msg.sender == dev, "dev: wut?");
        _burn(_from, _amount);
    }
}
