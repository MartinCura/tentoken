pragma solidity ^0.5.8;

import "./TenToken.sol";

/**
 * @title TENTOKEN with Futures
 * @author Martín Cura (95874)
 * @dev Extends TenToken with the ability to set up and execute futures
 */
contract TenWithFutures is TenToken {

    // Linear parameters from regression (multiplied by 10^6 to preserve precision)
    int256 regr_m;
    int256 regr_b;
    bool regressionCalculated = false;

    struct Future {
        uint32 date;
        address owner;
        uint256 amount;
        uint256 price;
        bool executed;
    }
    Future[] public futures;
    // Amount of *unexecuted* futures, by user and total
    mapping (address => uint) ownerFuturesCount;
    uint futuresCount;

    /**
     * @dev Constructor initializes contract.
     * @param _initialPrice Initial price in ether for token
     */
    constructor(uint256 _initialPrice)
            TenToken(_initialPrice)
        public {}

    function _buyAtPrice(address recipient, uint256 amount, uint256 _price) internal {
        _transfer(address(this), recipient, amount);
        _logTransaction(_price);
        _adjustPrice(true);
    }

    function executeRegression() public {
        require(lastTransactions[0].date != 0, "Not enough previous tx");
        uint256 avgDate = 0;
        uint256 avgPrice = 0;
        for (uint8 i = 0; i < lastTransactions.length; i++) {
            avgDate = avgDate.add(uint256(lastTransactions[i].date).div(lastTransactions.length));
            avgPrice = avgPrice.add(lastTransactions[i].price.div(lastTransactions.length));
        }
        int256 sumNum = 0;
        int256 sumDen = 0;
        for (uint8 i = 0; i < lastTransactions.length; i++) {
            sumNum = sumNum + int256((int256(avgDate) - int256(lastTransactions[i].date)) * (int256(avgPrice) - int256(lastTransactions[i].price)));
            sumDen = sumDen + int256((avgDate - lastTransactions[i].date) ** 2);
        }
        // Calculate the linear parameters multiplied by 10^6 to preserve some precision
        regr_m = (1e6 * sumNum) / sumDen;
        regr_b = 1e6 * int256(avgPrice) - regr_m * int256(avgDate);
        regressionCalculated = true;
    }

    function calculateFutureValue(uint32 date) public returns(uint256) {
        require(regressionCalculated, "Should executeRegression first");
        executeRegression();
        return uint256((regr_m * date + regr_b) / 1e6);
    }

    function buyFuture(uint32 date, uint256 amount) payable public {
        require(date > now, "Look towards the future, do not wallow in the past");
        require(date <= now + 90 days, "Can't buy more than 90 days in the future");
        uint256 futurePrice = calculateFutureValue(date);
        uint256 futureTotal = amount.mul(futurePrice);
        require(msg.value == futureTotal, "Incorrect amount sent");
        futures.push(Future(date, msg.sender, amount, futurePrice, false));
        ownerFuturesCount[msg.sender] = ownerFuturesCount[msg.sender].add(1);
        futuresCount = futuresCount.add(1);
    }

    /**
     * @dev Returns array of IDs for all unexecuted futures created by sender.
     * Can then obtain each with `futures` getter.
     */
    function getOwnFutures() public view returns(uint[] memory) {
        uint[] memory _ownFutures = new uint[](ownerFuturesCount[msg.sender]);
        uint k = 0;
        for (uint i = 0; i < futures.length; i++) {
            if (futures[i].owner == msg.sender && !futures[i].executed) {
                _ownFutures[k] = i;
                k++;
            }
        }
        return _ownFutures;
    }

    /**
     * @dev Returns array of IDs for all *unexecuted* futures. Can only be
     * used by the contract owner. Can then obtain each with `futures` getter.
     */
    function getAllFutures() onlyOwner public view returns(uint[] memory) {
        uint[] memory _allFutures = new uint[](futuresCount);
        uint k = 0;
        for (uint i = 0; i < futures.length; i++) {
            if (!futures[i].executed) {
                _allFutures[k] = i;
                k++;
            }
        }
        return _allFutures;
    }

    /**
     * TODO: Futures should have their amount of tokens left aside, "reserved".
     *   As of this moment, this is not so, and a future won't execute if
     *   the contract doesn't have enough tokens to satisfy it. Furthermore,
     *   this implementation is vulnerable to some race conditions but the
     *   only effect it would have is the caller public method exiting early.
     *   One way to solve this could be with a modified approve-transfer
     *   mechanism.
     */
    function _executeFuture(uint futureId) internal returns(bool) {
        Future memory fut = futures[futureId];
        if (fut.owner == msg.sender && fut.date <= now) {
            if (address(this).balance >= fut.amount) {
                _buyAtPrice(msg.sender, fut.amount, fut.price);
                futures[futureId].executed = true;
                ownerFuturesCount[msg.sender] = ownerFuturesCount[msg.sender].sub(1);
                futuresCount = futuresCount.sub(1);
                return true;
            }
        }
        return false;
    }

    function executeOwnContracts() public {
        for (uint i = 0; i < futures.length; i++) {
            if (futures[i].owner == msg.sender && !futures[i].executed) {
                _executeFuture(i);
            }
        }
    }

    function executeAllContracts() onlyOwner public {
        for (uint i = 0; i < futures.length; i++) {
            if (!futures[i].executed) {
                _executeFuture(i);
            }
        }
    }


    /**
     * Spanish interface / Interfaz en español
     */

    function ejecutarRegresion() public {
        return executeRegression();
    }

    function calcularValorFuturo(uint32 fecha) public returns(uint256) {
        return calculateFutureValue(fecha);
    }

    function comprarMonedaFutura(uint32 fecha, uint256 amount) payable public {
        return buyFuture(fecha, amount);
    }

    function consultarMisComprasFuturas() public view returns(uint[] memory) {
        return getOwnFutures();
    }

    function consultarTodasLasComprasFuturas() onlyOwner public view returns(uint[] memory) {
        return getAllFutures();
    }

    function ejecutarMisContratos() public {
        return executeOwnContracts();
    }

    function ejecutarTodosLosContratos() public {
        return executeAllContracts();
    }

}
