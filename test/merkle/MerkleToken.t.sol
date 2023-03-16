// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {IToken} from "../../src/tokens/interfaces/IToken.sol";
import {IFixedPriceToken} from "../../src/tokens/interfaces/IFixedPriceToken.sol";
import {FixedPriceTokenUtils} from "../utils/FixedPriceTokenUtils.sol";

import {MerkleData} from "./MerkleData.sol";

contract FixedPriceTokenTest is Test, FixedPriceTokenUtils {
    using StringsUpgradeable for uint256;
    MerkleData public merkleData;

    address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS =
        payable(address(0x21303));
    address payable public constant mintFeeRecipient = payable(address(0x1234));
    uint256 public constant mintFee = 0.000777 ether;

    function setUp() public {
        _setUp();
        merkleData = new MerkleData();
    }

    function test_MerklePurchaseActiveSuccess() public {
        vm.prank(factory);
        _initToken(10);

        vm.startPrank(owner);
        token.setSaleInfo({
            publicStartTime: 0,
            publicEndTime: 0,
            presaleStartTime: 0,
            presaleEndTime: type(uint64).max,
            publicPrice: 0 ether,
            merkleRoot: merkleData.getTestSetByName("test-3-addresses").root
        });
        vm.stopPrank();

        MerkleData.MerkleEntry memory item;

        item = merkleData.getTestSetByName("test-3-addresses").entries[0];
        vm.deal(address(item.user), 1 ether);
        vm.startPrank(address(item.user));

        token.purchasePresale{value: item.mintPrice}(
            1,
            item.maxMint,
            item.mintPrice,
            item.proof
        );
        assertEq(token.tokenInfo().maxSupply, 10);
        assertEq(token.tokenInfo().totalMinted, 2);
        require(
            token.ownerOf(1) == address(item.user),
            "owner is wrong for new minted token"
        );
        vm.stopPrank();

        item = merkleData.getTestSetByName("test-3-addresses").entries[1];
        vm.deal(address(item.user), 1 ether);
        vm.startPrank(address(item.user));

        token.purchasePresale{value: (item.mintPrice) * 2}(
            2,
            item.maxMint,
            item.mintPrice,
            item.proof
        );
        assertEq(token.tokenInfo().maxSupply, 10);
        assertEq(token.tokenInfo().totalMinted, 4);
        require(
            token.ownerOf(2) == address(item.user),
            "owner is wrong for new minted token"
        );
        vm.stopPrank();
    }

    function test_MerklePurchaseFailureWrongPrice() public {
        vm.prank(factory);
        _initToken(10);

        vm.startPrank(owner);

        token.setSaleInfo({
            publicStartTime: 0,
            publicEndTime: 0,
            presaleStartTime: 0,
            presaleEndTime: type(uint64).max,
            publicPrice: 0 ether,
            merkleRoot: merkleData.getTestSetByName("test-3-addresses").root
        });
        vm.stopPrank();

        MerkleData.MerkleEntry memory item;

        item = merkleData.getTestSetByName("test-3-addresses").entries[0];
        vm.deal(address(item.user), 1 ether);
        vm.startPrank(address(item.user));

        vm.expectRevert(IFixedPriceToken.InvalidPrice.selector);
        token.purchasePresale{value: item.mintPrice - 1}(
            1,
            item.maxMint,
            item.mintPrice,
            item.proof
        );
        assertEq(token.tokenInfo().maxSupply, 10);
        assertEq(token.tokenInfo().totalMinted, 1);
        vm.stopPrank();
    }

    function test_MerklePurchaseFailureWrongRoot() public {
        vm.prank(factory);
        _initToken(10);

        vm.startPrank(owner);
        token.setSaleInfo({
            publicStartTime: 0,
            publicEndTime: 0,
            presaleStartTime: 0,
            presaleEndTime: type(uint64).max,
            publicPrice: 0 ether,
            merkleRoot: merkleData.getTestSetByName("test-3-addresses").root
        });
        vm.stopPrank();

        MerkleData.MerkleEntry memory item;

        item = merkleData.getTestSetByName("test-3-addresses").entries[0];
        vm.deal(address(item.user), 1 ether);
        vm.startPrank(address(item.user));

        vm.expectRevert(IFixedPriceToken.InvalidProof.selector);
        item.proof[1] = item.proof[1] & bytes32(bytes4(0xcafecafe));
        token.purchasePresale{value: item.mintPrice}(
            1,
            item.maxMint,
            item.mintPrice,
            item.proof
        );
        assertEq(token.tokenInfo().maxSupply, 10);
        assertEq(token.tokenInfo().totalMinted, 1);
        vm.stopPrank();
    }

    function test_MerklePurchaseAndPublicSaleEditionSizeZero() public {
        vm.prank(factory);
        _initToken(1);

        bytes[] memory setupCalls = new bytes[](0);

        vm.startPrank(owner);
        token.setSaleInfo({
            publicStartTime: 0,
            publicEndTime: 0,
            presaleStartTime: 0,
            presaleEndTime: type(uint64).max,
            publicPrice: 0.1 ether,
            merkleRoot: merkleData.getTestSetByName("test-2-prices").root
        });
        vm.stopPrank();

        MerkleData.MerkleEntry memory item;

        item = merkleData.getTestSetByName("test-2-prices").entries[0];
        vm.deal(address(item.user), 1 ether);
        vm.startPrank(address(item.user));

        vm.expectRevert(IFixedPriceToken.SoldOut.selector);
        token.purchasePresale{value: item.mintPrice}(
            1,
            item.maxMint,
            item.mintPrice,
            item.proof
        );
        vm.stopPrank();
    }

    function test_MerklePurchaseInactiveFails() public {
        vm.prank(factory);
        _initToken(10);

        vm.startPrank(owner);
        // block.timestamp returning zero allows sales to go through.
        vm.warp(100);
        token.setSaleInfo({
            publicStartTime: 0,
            publicEndTime: 0,
            presaleStartTime: 0,
            presaleEndTime: 0,
            publicPrice: 0 ether,
            merkleRoot: merkleData.getTestSetByName("test-2-prices").root
        });

        vm.stopPrank();
        vm.deal(address(0x10), 1 ether);

        vm.startPrank(address(0x10));
        MerkleData.MerkleEntry memory item = merkleData
            .getTestSetByName("test-3-addresses")
            .entries[0];
        vm.expectRevert(IFixedPriceToken.SaleNotActive.selector);
        token.purchasePresale{value: item.mintPrice}(
            1,
            item.maxMint,
            item.mintPrice,
            item.proof
        );
    }
}
