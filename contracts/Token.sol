//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MintToken is ERC20 {
    constructor() ERC20("CoinTicket","CTK") {}
    
}