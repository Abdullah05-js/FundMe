// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error PriceError();

library PriceConverter {
    function getPrice(address _priceFeed) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, PriceError());
        uint8 dec = priceFeed.decimals();
        return uint256(price) * 10 ** (18 - dec);
    }

    function getConversionRate(uint256 ethAmount, address _priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        return (ethPrice * ethAmount) / 1e18;
    }

    function getVersion(address _priceFeed) internal view returns (uint256) {
        return AggregatorV3Interface(_priceFeed).version();
    }
}
