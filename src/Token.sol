//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Token {
    mapping(address => uint256) private balances;

    function name() external pure returns (string memory) {
        return "IDNT";
    }

    function totalSupply() public pure returns (uint256) {
        return 1000 ether;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address _to, uint256 amount) public {
        uint256 previousBalance = balanceOf(msg.sender) + balanceOf(_to);
        balances[msg.sender] -= amount;
        balances[_to] += amount;
        require(balanceOf(msg.sender) + balanceOf(_to) == previousBalance);
    }
}
