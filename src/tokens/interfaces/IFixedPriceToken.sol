//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFixedPriceToken {
    struct SaleInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    error SaleNotActive();
    error InvalidPrice();
    error SoldOut();
}
