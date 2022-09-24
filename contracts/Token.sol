//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
contract MintToken is ERC20Capped, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    constructor(uint256 cap, address addressTicket) ERC20("CoinTicket","CTK") ERC20Capped(cap){
         _grantRole(MINTER_ROLE, addressTicket);
    }

    function issueToken(address receiver, uint256 amount) public{
        require(hasRole(MINTER_ROLE, msg.sender));
        _mint(receiver, amount);
    }
}