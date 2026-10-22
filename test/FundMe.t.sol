// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.36;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {PriceConverter} from "../src/PriceConverters.sol";
import {FundMeDeployer} from "../script/FundMe.s.sol";

contract FundMeTest is Test {
    address public USER = makeAddr("user");
    uint256 public constant SEND_VALUE = 0.1 ether;
    FundMe public fundMe;
    FundMeDeployer public deployer;

    function setUp() external {
        deployer = new FundMeDeployer();
        fundMe = deployer.run();
        vm.deal(USER, 10 ether);
    }

    function testMIN_USD() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.owner(), msg.sender);
    }

    function testFund() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        console.log(fundMe.getAddressToAmountFunded(USER));
        console.log(fundMe.getFunders(0));
        console.log(PriceConverter.getPrice(address(fundMe.PRICE_FEED())));
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
        assertEq(fundMe.getFunders(0), USER);
    }

    function test_FailIfnotEnoughEthFunded() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testWithdraw() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 startingOwnerBalance = fundMe.owner().balance;
        uint256 startingContractBalance = address(fundMe).balance;
        console.log("startingOwnerBalance: ", startingOwnerBalance);
        console.log("startingContractBalance: ", startingContractBalance);
        vm.prank(fundMe.owner());
        fundMe.withdraw();
        uint256 endingOwnerBalance = fundMe.owner().balance;
        uint256 endingContractBalance = address(fundMe).balance;
        console.log("endingOwnerBalance: ", endingOwnerBalance);
        console.log("endingContractBalance: ", endingContractBalance);
        assertEq(endingContractBalance, 0);
        assertEq(
            startingOwnerBalance + startingContractBalance,
            endingOwnerBalance
        );
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testWithdrawWithUser() public funded {
        uint256 startingOwnerBalance = fundMe.owner().balance;
        uint256 startingContractBalance = address(fundMe).balance;
        console.log("startingOwnerBalance: ", startingOwnerBalance);
        console.log("startingContractBalance: ", startingContractBalance);
        vm.expectRevert();
        fundMe.withdraw();
    }


}
