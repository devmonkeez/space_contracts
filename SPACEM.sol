// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpacemToken is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("Spacem Token", "SPACEM")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 50000000000 * 10 ** decimals());
    }
}
