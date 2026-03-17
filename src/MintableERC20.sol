// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MintableERC20 is ERC20, Ownable {
    uint8 private immutable _customDecimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address initialOwner_)
        ERC20(name_, symbol_)
        Ownable(initialOwner_)
    {
        _customDecimals = decimals_;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _customDecimals;
    }
}
