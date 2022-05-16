// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerMaticDollar {

    uint8 DataDecimal;
    uint8 public decimalValue =18;
    AggregatorV3Interface internal priceFeed;
    /**
     * Network: MUMBAI
     * Aggregator: MATIC/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        decimalValue = 18;
    }

    function decimalValueData() public returns (uint8){
        DataDecimal = priceFeed.decimals();
        return DataDecimal;
    }
    /**
     * Returns the latest price
     */
    function getPriceDolarperMaticLink()  public view returns (int256) {
        (
            /*uint80 roundID*/,
            int256 _price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return _price;
    }

    function getPriceDolarperMatic() public view returns(int256){
        int256 price = getPriceDolarperMaticLink()* 10**10;
        return price;
    }

    function getPriceMaticperDolar() public view returns (int256){
        int256 _price = getPriceDolarperMaticLink();
        int256 dec = 10**26;
        return dec/_price;
    }

    function getPriceUSD(int256 matic) public view returns(int256){
        int256 price = matic*getPriceMaticperDolar();  
        return price;
    }

    function getPriceMATIC(int usd) public view returns(int){
        int matic = usd * getPriceDolarperMatic();
        return matic;
    }

}