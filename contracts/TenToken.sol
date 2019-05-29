pragma solidity ^0.5.8;

import "./util/ERC20.sol";
import "./util/ERC20Detailed.sol";
import "./util/Ownable.sol";

/**
 * @title TENTOKEN
 * @author Martín Cura (95874)
 * @dev ERC20 token conforming TP2 specification. All prices in wei (10^-18 ether)!
 */
contract TenToken is ERC20, ERC20Detailed, Ownable {

    uint8 public constant LAST_TRANSACTIONS_SIZE = 4;

    uint256 public initialPrice;
    // Current token value in wei
    uint256 public price;

    // Allowed ether withdrawals after selling token
    // mapping (address => uint) pendingReturns;

    struct Transaction {
        uint32 date;
        uint256 price;
    }
    Transaction[LAST_TRANSACTIONS_SIZE] public lastTransactions;

    /**
     * @dev Constructor initializes contract.
     * @param _initialPrice Initial price in ether for token
     */
    constructor(uint256 _initialPrice)
            ERC20Detailed("TenToken", "_X_", 18)
            ERC20()
            Ownable()
            public {
        require(_initialPrice > 0);
        // Initial price (e.g. 0.0001 ether)
        initialPrice = _initialPrice * 1 wei;
        price = _initialPrice;
        // All tokens are created and given to the contract
        _mint(address(this), 1e6 * 1e18);
    }

    /**
     * @dev Log a transaction, whether selling or buying, only for its price.
     */
    function _logTransaction(uint256 _price) internal {
        for (uint8 i = 0; i < LAST_TRANSACTIONS_SIZE - 1; i++) {
            lastTransactions[i] = lastTransactions[i + 1];
        }
        lastTransactions[LAST_TRANSACTIONS_SIZE - 1] = Transaction(uint32(now), _price);
    }

    /**
     * @dev Adjusts price by `pctDif` % (to call with each buy/sell operation)
     */
    uint8 pctDif = 2;
    function _adjustPrice(bool buy) internal {
        // price = uint256(1e6 * initialPrice * 2.718282 ** (-13.8155106 * address(this).balance / TOTAL_SUPPLY));
        // price = totalSupply().mul(initialPrice).div(address(this).balance.add(1));
        if (buy) {
            price = price.mul(100 + pctDif).div(100);
        } else {
            price = price.mul(100 - pctDif).div(100);
        }
    }

    /// @dev Buy token from contract with ether
    /// @param amount Of token to buy
    function buy(uint256 amount) public payable {
        require(msg.value == amount.mul(price), "Ether sent does not equal the value needed");
        _transfer(address(this), msg.sender, amount);
        _logTransaction(price);
        _adjustPrice(true);
    }

    /**
     * @dev Sell token to contract for ether.
     * @param amount Of token to sell
     */
    function sell(uint256 amount) public {
        uint256 value = amount.mul(price);
        _transfer(msg.sender, address(this), amount);
        msg.sender.transfer(value);
        // pendingReturns[seller] += amount;
        _logTransaction(price);
        _adjustPrice(false);
    }

    /// @dev We should use the withdrawal pattern as it's safer
    /// Should do pendingReturns[seller] += in sell()
    // function withdraw() public returns(bool) {
    //     uint amount = pendingReturns[msg.sender];
    //     if (amount > 0) {
    //         pendingReturns[msg.sender] = 0;
    //         if (!msg.sender.send(amount)) {
    //             pendingReturns[msg.sender] = amount;
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    /// @dev Retrieve ether balance, only callable by contract owner (deployer if not changed)
    function retrieve() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

}
