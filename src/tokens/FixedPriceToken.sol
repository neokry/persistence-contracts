// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

import {IObservability} from "../observability/Observability.sol";
import {IFixedPriceToken} from "./interfaces/IFixedPriceToken.sol";
import {InitArgs} from "./FixedPriceTokenInitilizer.sol";
import {TokenBase} from "../TokenBase.sol";
import {WithStorage, FixedPriceSaleInfo} from "../libraries/LibStorage.sol";
import {FixedPriceTokenInitilizer} from "./FixedPriceTokenInitilizer.sol";

contract FixedPriceToken is
    IFixedPriceToken,
    WithStorage,
    FixedPriceTokenInitilizer,
    TokenBase
{
    using StringsUpgradeable for uint256;

    modifier onlyValidAmount(uint256 amount) {
        if (amount == 0) revert InvalidAmount();
        _;
    }

    modifier onlyNotSoldOut(uint256 amount) {
        if (totalSupply() > 0 && totalSupply() + amount > ts().maxSupply)
            revert SoldOut();
        _;
    }

    modifier onlySaleActive() {
        if (
            block.timestamp < fixedPriceSaleInfo().publicStartTime ||
            block.timestamp >= fixedPriceSaleInfo().publicEndTime
        ) revert SaleNotActive();
        _;
    }

    modifier onlyPresaleActive() {
        if (
            block.timestamp < fixedPriceSaleInfo().presaleStartTime ||
            block.timestamp >= fixedPriceSaleInfo().presaleEndTime
        ) revert SaleNotActive();
        _;
    }

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
                merkleRoot: fixedPriceSaleInfo().merkleRoot
            });
    }

    //[[[[PURCHASE FUNCTIONS]]]]

    /// @notice purchase a number of tokens
    function purchase(
        uint256 amount
    )
        external
        payable
        nonReentrant
        onlySaleActive
        onlyNotSoldOut(amount)
        onlyValidAmount(amount)
    {
        // Check if price is correct
        if (msg.value < (amount * fixedPriceSaleInfo().publicPrice))
            revert InvalidPrice();

        _purchase(amount);

        IObservability(ts().o11y).emitSale(
            msg.sender,
            fixedPriceSaleInfo().publicPrice,
            amount
        );
    }

    /// @notice purchase a number of tokens
    function purchasePresale(
        uint256 amount,
        uint256 maxMints,
        uint256 pricePerToken,
        bytes32[] calldata proof
    )
        external
        payable
        nonReentrant
        onlyPresaleActive
        onlyNotSoldOut(amount)
        onlyValidAmount(amount)
    {
        // Check if price is correct
        if (msg.value < (amount * pricePerToken)) revert InvalidPrice();

        // Validate presale proof
        _validatePresale(proof, maxMints, pricePerToken);

        fixedPriceSaleInfo().presaleMintsByAddress[msg.sender] += amount;

        // Check if user has exceeded max mints
        if (fixedPriceSaleInfo().presaleMintsByAddress[msg.sender] > maxMints)
            revert MaxPresaleMintsForUserExceeded();

        _purchase(amount);

        IObservability(ts().o11y).emitSale(msg.sender, pricePerToken, amount);
    }

    //[[[ SET SALE FUNCTIONS ]]]

    function setSaleInfo(
        uint128 publicPrice,
        uint64 publicStartTime,
        uint64 publicEndTime,
        uint64 presaleStartTime,
        uint64 presaleEndTime,
        bytes32 merkleRoot
    ) public onlyOwner {
        fixedPriceSaleInfo().presaleStartTime = presaleStartTime;
        fixedPriceSaleInfo().presaleEndTime = presaleEndTime;
        fixedPriceSaleInfo().publicStartTime = publicStartTime;
        fixedPriceSaleInfo().publicEndTime = publicEndTime;
        fixedPriceSaleInfo().publicPrice = publicPrice;
        fixedPriceSaleInfo().merkleRoot = merkleRoot;

        emit SaleInfoSet(
            publicPrice,
            publicStartTime,
            publicEndTime,
            presaleStartTime,
            presaleEndTime,
            merkleRoot
        );
    }

    //[[[ INTERNAL FUNCTIONS ]]]]]

    function _validatePresale(
        bytes32[] calldata proof,
        uint256 maxMints,
        uint256 pricePerToken
    ) internal view {
        if (
            MerkleProofUpgradeable.verifyCalldata(
                proof,
                fixedPriceSaleInfo().merkleRoot,
                keccak256(abi.encode(msg.sender, maxMints, pricePerToken))
            ) == false
        ) revert InvalidProof();
    }

    function _purchase(uint256 amount) private {
        _seedAndMintMany(msg.sender, amount);
    }
}
