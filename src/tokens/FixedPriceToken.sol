// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

import {IObservability} from "../observability/Observability.sol";
import {IFixedPriceToken} from "./interfaces/IFixedPriceToken.sol";
import {InitArgs} from "./FixedPriceTokenInitilizer.sol";
import {TokenBase} from "../TokenBase.sol";
import {WithStorage, FixedPriceSaleInfo} from "../libraries/LibStorage.sol";
import {LibMetadata} from "../libraries/LibMetadata.sol";
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
    ) TokenBase(_factory, _o11y, _feeManager, _ethFS) {
        _disableInitializers();
    }

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

    function saleDetails() public view returns (FixedPriceSaleDetails memory) {
        return
            FixedPriceSaleDetails({
                publicStartTime: fixedPriceSaleInfo().publicStartTime,
                publicEndTime: fixedPriceSaleInfo().publicEndTime,
                presaleStartTime: fixedPriceSaleInfo().presaleStartTime,
                presaleEndTime: fixedPriceSaleInfo().presaleEndTime,
                publicPrice: fixedPriceSaleInfo().publicPrice,
                presalePrice: fixedPriceSaleInfo().presalePrice,
                maxPresaleMintsPerAddress: fixedPriceSaleInfo()
                    .maxPresaleMintsPerAddress,
                merkleRoot: fixedPriceSaleInfo().merkleRoot
            });
    }

    //[[[[PURCHASE FUNCTIONS]]]]

    /// @notice purchase a number of tokens
    function purchase(uint256 amount) external payable nonReentrant {
        // Check if sale is active
        if (
            block.timestamp < fixedPriceSaleInfo().publicStartTime ||
            block.timestamp >= fixedPriceSaleInfo().publicEndTime
        ) revert SaleNotActive();

        // Check if price is correct
        if (msg.value < (amount * fixedPriceSaleInfo().publicPrice))
            revert InvalidPrice();

        // Check if there are enough tokens left
        if (totalSupply() + amount > ts().maxSupply) revert SoldOut();

        // Check if amount is nonzero
        if (amount < 1) revert InvalidAmount();

        _purchase(amount);
    }

    /// @notice purchase a number of tokens
    function purchasePresale(
        uint256 amount,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        // Check if presale is active
        if (
            block.timestamp < fixedPriceSaleInfo().presaleStartTime ||
            block.timestamp >= fixedPriceSaleInfo().presaleEndTime
        ) revert SaleNotActive();

        // Check if price is correct
        if (msg.value < (amount * fixedPriceSaleInfo().presalePrice))
            revert InvalidPrice();

        // Check if there are enough tokens left
        if (totalSupply() + amount > ts().maxSupply) revert SoldOut();

        // Check if amount is nonzero
        if (amount < 1) revert InvalidAmount();

        // Check if user is in presale
        if (
            MerkleProofUpgradeable.verifyCalldata(
                proof,
                fixedPriceSaleInfo().merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ) == false
        ) revert InvalidProof();

        // Check if user has not exceeded max mints
        fixedPriceSaleInfo().presaleMintsByAddress[msg.sender] += amount;

        if (
            fixedPriceSaleInfo().presaleMintsByAddress[msg.sender] >
            fixedPriceSaleInfo().maxPresaleMintsPerAddress
        ) revert MaxPresaleMintsForUserExceeded();

        _purchase(amount);
    }

    //[[[ INTERNAL FUNCTIONS ]]]]]

    function _purchase(uint256 amount) internal {
        _seedAndMintMany(msg.sender, amount);
        IObservability(ts().o11y).emitSale(
            msg.sender,
            fixedPriceSaleInfo().publicPrice,
            amount
        );
    }
}
