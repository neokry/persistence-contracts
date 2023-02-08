// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {LibStorage, FixedPriceSaleInfo, TokenStorage} from "./LibStorage.sol";
import {IFixedPriceToken} from "../tokens/interfaces/IFixedPriceToken.sol";

library LibFixedPriceToken {
    function ts() internal pure returns (TokenStorage storage) {
        return LibStorage.tokenStorage();
    }

    function fps() internal pure returns (FixedPriceSaleInfo storage) {
        return LibStorage.fixedPriceSaleInfo();
    }

    function validatePublicSale(uint256 amount, uint256 totalSupply) external {
        if (
            block.timestamp < fps().publicStartTime ||
            block.timestamp >= fps().publicEndTime
        ) revert IFixedPriceToken.SaleNotActive();

        if (msg.value < (amount * fps().publicPrice))
            revert IFixedPriceToken.InvalidPrice();
        if (totalSupply + amount > ts().maxSupply)
            revert IFixedPriceToken.SoldOut();
        if (amount < 1) revert IFixedPriceToken.InvalidAmount();
    }

    function validatePresale(uint256 amount, uint256 totalSupply) external {
        if (
            block.timestamp < fps().presaleStartTime ||
            block.timestamp >= fps().presaleEndTime
        ) revert IFixedPriceToken.SaleNotActive();

        if (msg.value < (amount * fps().presalePrice))
            revert IFixedPriceToken.InvalidPrice();
        if (totalSupply + amount > ts().maxSupply)
            revert IFixedPriceToken.SoldOut();
        if (amount < 1) revert IFixedPriceToken.InvalidAmount();
    }
}
