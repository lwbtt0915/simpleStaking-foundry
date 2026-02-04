// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 自定义可铸造的ERC20代币（解决抽象合约和mint方法问题）
contract TestToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
        Ownable(msg.sender) 
    {}

    // 外部可调用的mint方法（仅拥有者）
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}