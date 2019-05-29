TenToken
========

Simple ERC20 token contracts made with Solidity v0.5.8.

- TenToken: ERC20 whose price adjusts with each buy or sell by a fixed amount (it's a hassle to make more complicated equations work in current beta Solidity).
- TenWithFutures: Adds to the last the ability to buy futures up to 90 days in advance and execute them after the date. So exploitable it's funny.

Done as part of a weekend trying Solidity, laughably not production-level.
All base contracts used are [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-solidity)'s.
