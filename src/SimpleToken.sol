// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleToken is ERC20, ERC20Burnable, Ownable {
    // only admin can do all tasks, minter can only mint

    constructor() ERC20("MyToken", "MTK") Ownable(msg.sender) {

    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {

        _burn(from, amount);
    }
}