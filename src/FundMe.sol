// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.36;

error FundMe__NotOwner();
error FundMe__NotEnoughEth();
error FundMe__PriceError();

import {PriceConverter} from "./PriceConverters.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18; // 5 * 10 ** 18 weis
    address public immutable owner;
    AggregatorV3Interface public immutable PRICE_FEED;
    address[] private funders;
    mapping(address => uint256) private addressToAmountFunded;
    
    constructor( address _priceFeed) {
        owner = msg.sender;
        PRICE_FEED = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, FundMe__NotOwner());
        _;
    }

    function fund() external payable {
        require(
            PriceConverter.getConversionRate(msg.value, address(PRICE_FEED)) >= MINIMUM_USD,
            FundMe__NotEnoughEth()
        );
        uint256 funded = addressToAmountFunded[msg.sender];
        if (funded == 0) funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = funded + msg.value;
    }

    function withdraw() external onlyOwner {
        uint256 length = funders.length;
        for (uint256 i = 0; i < length; i++) {
            delete addressToAmountFunded[funders[i]];
        }
        delete funders;
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, FundMe__PriceError());
    }

    function getFunders(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return addressToAmountFunded[funder];
    }
}
