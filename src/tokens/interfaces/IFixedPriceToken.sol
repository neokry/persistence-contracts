//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IToken} from "./IToken.sol";
import {LibStorage} from "../../libraries/LibStorage.sol";

interface IFixedPriceToken {
    error SaleNotActive();
    error InvalidPrice();
    error SoldOut();
    error InvalidInteraction();
    error InteractorNotSet();
    error InvalidTokenId();
    error InvalidAmount();
    error InvalidProof();
    error MaxPresaleMintsForUserExceeded();

    struct FixedPriceSaleDetails {
        uint128 publicPrice;
        uint64 publicStartTime;
        uint64 publicEndTime;
        uint64 presaleStartTime;
        uint64 presaleEndTime;
        bytes32 merkleRoot;
    }

    /// @notice initialize the token
    function initialize(address owner, bytes calldata data) external;
}
