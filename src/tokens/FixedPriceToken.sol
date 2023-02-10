// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {IObservability} from "../observability/Observability.sol";
import {IFixedPriceToken} from "./interfaces/IFixedPriceToken.sol";
import {InitArgs} from "./FixedPriceTokenInitilizer.sol";
import {TokenBase} from "../TokenBase.sol";
import {WithStorage, FixedPriceSaleInfo} from "../libraries/LibStorage.sol";
import {LibMetadata} from "../libraries/LibMetadata.sol";
import {LibFixedPriceToken} from "../libraries/LibFixedPriceToken.sol";
import {FixedPriceTokenInitilizer} from "./FixedPriceTokenInitilizer.sol";

contract FixedPriceToken is
    IFixedPriceToken,
    WithStorage,
    FixedPriceTokenInitilizer,
    TokenBase
{
    using StringsUpgradeable for uint256;

    //[[[[SETUP FUNCTIONS]]]]

    constructor(
        address _factory,
        address _o11y,
        address _feeManager,
        address _ethFS
    ) TokenBase(_factory, _o11y, _feeManager, _ethFS) {}

    function initialize(
        address owner,
        bytes calldata data
    ) external initializer {
        if (msg.sender != factory) revert FactoryMustInitilize();

        InitArgs memory args = _init(
            owner,
            factory,
            o11y,
            feeManager,
            ethFS,
            data
        );

        __ERC721_init(args.name, args.symbol);
        _transferOwnership(owner);
        _mintArtistProofs(args.artistProofCount);
    }

    function saleInfo() public pure returns (FixedPriceSaleInfo memory) {
        return fixedPriceSaleInfo();
    }

    //[[[[PURCHASE FUNCTIONS]]]]

    /// @notice purchase a number of tokens
    function purchase(uint256 amount) external payable nonReentrant {
        LibFixedPriceToken.validatePublicSale(amount, totalSupply());
        _seedAndMintMany(msg.sender, amount);
        IObservability(ts().o11y).emitSale(
            msg.sender,
            fixedPriceSaleInfo().publicPrice,
            amount
        );
    }
}
