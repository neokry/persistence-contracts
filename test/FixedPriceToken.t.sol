// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {IFixedPriceToken} from "../src/tokens/interfaces/IFixedPriceToken.sol";
import {ITokenFactory} from "../src/interfaces/ITokenFactory.sol";
import {FixedPriceSaleInfo} from "../src/libraries/LibStorage.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {InitArgs} from "../src/tokens/FixedPriceTokenInitilizer.sol";
import {Observability} from "../src/observability/Observability.sol";
import {TokenProxy} from "../src/TokenProxy.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {LibHTMLRenderer} from "../src/libraries/LibHTMLRenderer.sol";

import {FixedPriceTokenUtils} from "./utils/FixedPriceTokenUtils.sol";

contract FixedPriceTokenTest is Test, FixedPriceTokenUtils {
    using StringsUpgradeable for uint256;

    function setUp() public {
        _setUp();
    }

    function test_onlyFactoryCanInitilize() public {
        vm.prank(factory);
        _initToken();

        IToken.TokenInfo memory tokenInfo = token.tokenInfo();
        IToken.MetadataInfo memory metadataInfo = token.metadataInfo();
        FixedPriceSaleInfo memory saleInfo = token.saleInfo();

        require(
            keccak256(abi.encodePacked(metadataInfo.urlEncodedName)) ==
                keccak256(abi.encodePacked("Test")),
            "Invalid name"
        );
        require(
            keccak256(abi.encodePacked(metadataInfo.symbol)) ==
                keccak256(abi.encodePacked("TST")),
            "Invalid symbol"
        );
        require(
            keccak256(abi.encodePacked(metadataInfo.urlEncodedDescription)) ==
                keccak256(abi.encodePacked("Test description")),
            "Invalid description"
        );
        require(tokenInfo.fundsRecipent == owner, "Invalid fundsRecipent");
        require(tokenInfo.maxSupply == 10, "Invalid totalSupply");

        require(saleInfo.publicStartTime == startTime, "Invalid startTime");
        require(saleInfo.publicEndTime == endTime, "Invalid endTime");

        require(saleInfo.publicPrice == 1 ether, "Invalid price");
        require(token.totalSupply() == 1, "Proofs not minted");
    }

    function testRevert_onlyFactoryCanInitilize() public {
        vm.expectRevert();
        _initToken();
    }

    function test_purchase() public {
        vm.prank(factory);
        _initToken();

        vm.deal(user, 1 ether);

        uint256 prevBalance = user.balance;

        vm.startPrank(user);
        token.purchase{value: 1 ether}(1);
        vm.stopPrank();

        require(prevBalance - user.balance == 1 ether);
    }

    function test_purchaseMultiple() public {
        vm.prank(factory);
        _initToken();

        vm.deal(user, 9 ether);

        vm.startPrank(user);
        token.purchase{value: 9 * 1 ether}(9);
        vm.stopPrank();
    }

    function test_purchaseZero() public {
        vm.prank(factory);
        _initToken();

        vm.startPrank(user);
        vm.expectRevert(IFixedPriceToken.InvalidAmount.selector);
        token.purchase(0);
        vm.stopPrank();
    }

    function testRevert_soldOut() public {
        vm.prank(factory);
        _initToken();

        vm.deal(user, 11 ether);

        vm.startPrank(user);
        vm.expectRevert(IFixedPriceToken.SoldOut.selector);
        token.purchase{value: 11 * 1 ether}(11);
        vm.stopPrank();
    }

    function testRevert_purchaseSaleNotActive() public {
        vm.prank(factory);
        _initToken();

        vm.deal(user, 1 ether);
        vm.warp(endTime + 1 seconds);

        vm.startPrank(user);

        vm.expectRevert(IFixedPriceToken.SaleNotActive.selector);
        token.purchase(1);

        vm.warp(startTime - 1 seconds);

        vm.expectRevert(IFixedPriceToken.SaleNotActive.selector);
        token.purchase(1);

        vm.stopPrank();
    }

    function testRevert_purchaseInvalidPrice() public {
        vm.prank(factory);
        _initToken();

        vm.deal(user, 1 ether);

        vm.startPrank(user);
        vm.expectRevert(IFixedPriceToken.InvalidPrice.selector);
        token.purchase(1);
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.prank(factory);
        _initToken();

        vm.deal(user, 1 ether);

        (, uint256 fee) = token.feeForAmount(1 ether);

        vm.startPrank(user);
        token.purchase{value: 1 ether}(1);
        vm.stopPrank();

        uint256 prevBalance = owner.balance;
        vm.startPrank(owner);
        token.withdraw();

        vm.stopPrank();

        require(owner.balance - prevBalance == 1 ether - fee);
    }

    function test_multiWithdraw() public {
        vm.prank(factory);
        _initToken();

        vm.deal(user, 2 ether);

        (, uint256 fee) = token.feeForAmount(2 ether);

        vm.startPrank(user);
        token.purchase{value: 2 * 1 ether}(2);
        vm.stopPrank();

        uint256 prevBalance = owner.balance;
        vm.startPrank(owner);
        token.withdraw();
        vm.stopPrank();

        require(owner.balance - prevBalance == 2 ether - fee);
    }

    function test_multiWithdrawMultiUser() public {
        vm.prank(factory);
        _initToken();

        vm.deal(user, 2 ether);

        (, uint256 fee) = token.feeForAmount(5 ether);

        vm.startPrank(user);
        token.purchase{value: 2 * 1 ether}(2);
        vm.stopPrank();

        vm.deal(otherUser, 3 ether);

        vm.startPrank(otherUser);
        token.purchase{value: 3 * 1 ether}(3);
        vm.stopPrank();

        uint256 prevBalance = owner.balance;
        vm.startPrank(owner);
        token.withdraw();
        vm.stopPrank();

        require(owner.balance - prevBalance == 5 ether - fee);
    }

    function test_ownerSafeMint() public {
        vm.prank(factory);
        _initToken();

        vm.startPrank(owner);
        token.safeMint(owner);
        vm.stopPrank();
    }

    function testRevert_unverifiedSafeMint() public {
        vm.prank(factory);
        _initToken();

        vm.startPrank(user);
        vm.expectRevert(IToken.SenderNotMinter.selector);
        token.safeMint(user);
        vm.stopPrank();
    }

    function test_upgrade() public {
        vm.prank(factory);
        _initToken();

        vm.startPrank(owner);
        token.upgradeTo(tokenImplUpgrade);
        vm.stopPrank();
    }

    function testRevert_upgradeNotRegistered() public {
        vm.prank(factory);
        _initToken();

        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSignature("InvalidUpgrade(address)", address(this))
        );
        token.upgradeTo(address(this));
        vm.stopPrank();
    }

    function testRevert_upgradeNotOwner() public {
        vm.prank(factory);
        _initToken();

        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        token.upgradeTo(tokenImplUpgrade);
        vm.stopPrank();
    }

    function testRevert_upgradeToAndCallNotRegistered() public {
        vm.prank(factory);
        _initToken();

        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSignature("InvalidUpgrade(address)", address(this))
        );
        token.upgradeToAndCall(address(this), "");
        vm.stopPrank();
    }

    function testRevert_upgradeToAndCallNotOwner() public {
        vm.prank(factory);
        _initToken();

        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        token.upgradeToAndCall(tokenImplUpgrade, "");
        vm.stopPrank();
    }

    function testGeneratePreviewURI() public {
        vm.prank(factory);
        _initToken();

        string memory previewURI = token.generatePreviewURI("0");
        string memory expected = string.concat(
            previewBaseURI,
            uint256(uint160(address(token))).toHexString(20),
            "/",
            "0"
        );

        require(
            keccak256(abi.encodePacked(previewURI)) ==
                keccak256(abi.encodePacked(expected))
        );
    }
}
