// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {HTMLFixedPriceToken} from "../src/tokens/HTMLFixedPriceToken.sol";
import {IHTMLFixedPriceToken} from "../src/tokens/interfaces/IHTMLFixedPriceToken.sol";
import {HTMLRenderer} from "../src/renderers/HTMLRenderer.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {Observability} from "../src/Observability/Observability.sol";
import {IHTMLRenderer} from "../src/renderers/interfaces/IHTMLRenderer.sol";
import {TokenProxy} from "../src/TokenProxy.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {ITokenFactory} from "../src/interfaces/ITokenFactory.sol";

contract HTMLFixedPriceTokenTest is Test {
    HTMLFixedPriceToken token;
    address factory = address(1);
    address owner = address(2);
    address user = address(3);
    address otherUser = address(4);
    address rendererImpl = address(5);
    address fileSystem = address(6);
    address tokenImplUpgrade;
    uint256 startTime = 0;
    uint256 endTime = 0;
    string script = "let x = 1;";

    function setUp() public {
        address o11y = address(new Observability());
        TokenFactory tokenFactory = new TokenFactory();
        factory = address(tokenFactory);

        address tokenImpl = address(new HTMLFixedPriceToken(factory, o11y));

        tokenImplUpgrade = address(new HTMLFixedPriceToken(factory, o11y));
        rendererImpl = address(new HTMLRenderer(factory));

        tokenFactory.registerDeployment(tokenImpl);
        tokenFactory.registerDeployment(rendererImpl);

        tokenFactory.registerUpgrade(tokenImpl, tokenImplUpgrade);

        token = HTMLFixedPriceToken(address(new TokenProxy(tokenImpl, "")));

        startTime = block.timestamp;
        endTime = block.timestamp + 2 days;
    }

    function test_onlyFactoryCanInitilize() public {
        vm.prank(factory);
        initToken();

        (
            string memory name,
            string memory symbol,
            string memory description,
            address fundsRecipent,
            uint256 totalSupply
        ) = token.tokenInfo();

        (uint256 saleStart, uint256 saleEnd, uint256 price) = token.saleInfo();

        require(
            keccak256(abi.encodePacked(name)) ==
                keccak256(abi.encodePacked("Test")),
            "Invalid name"
        );
        require(
            keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("TST")),
            "Invalid symbol"
        );
        require(
            keccak256(abi.encodePacked(description)) ==
                keccak256(abi.encodePacked("Test description")),
            "Invalid description"
        );
        require(fundsRecipent == owner, "Invalid fundsRecipent");
        require(totalSupply == 10, "Invalid totalSupply");

        require(saleStart == startTime, "Invalid startTime");
        require(saleEnd == endTime, "Invalid endTime");

        require(price == 1 ether, "Invalid price");
    }

    function testRevert_onlyFactoryCanInitilize() public {
        vm.expectRevert();
        initToken();
    }

    function test_purchase() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 1 ether);

        uint256 prevBalance = user.balance;

        vm.startPrank(user);
        token.purchase{value: 1 ether}(1);
        vm.stopPrank();

        require(prevBalance - user.balance == 1 ether);
    }

    function test_purchaseMultiple() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 10 ether);

        vm.startPrank(user);
        token.purchase{value: 10 * 1 ether}(10);
        vm.stopPrank();
    }

    function testRevert_soldOut() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 11 ether);

        vm.startPrank(user);
        vm.expectRevert(IHTMLFixedPriceToken.SoldOut.selector);
        token.purchase{value: 11 * 1 ether}(11);
        vm.stopPrank();
    }

    function testRevert_purchaseSaleNotActive() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 1 ether);
        vm.warp(endTime + 1 seconds);

        vm.startPrank(user);

        vm.expectRevert(IHTMLFixedPriceToken.SaleNotActive.selector);
        token.purchase(1);

        vm.warp(startTime - 1 seconds);

        vm.expectRevert(IHTMLFixedPriceToken.SaleNotActive.selector);
        token.purchase(1);

        vm.stopPrank();
    }

    function testRevert_purchaseInvalidPrice() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 1 ether);

        vm.startPrank(user);
        vm.expectRevert(IHTMLFixedPriceToken.InvalidPrice.selector);
        token.purchase(1);
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 1 ether);

        vm.startPrank(user);
        token.purchase{value: 1 ether}(1);
        vm.stopPrank();

        uint256 prevBalance = owner.balance;
        vm.startPrank(owner);
        token.withdraw();
        vm.stopPrank();

        require(owner.balance - prevBalance == 1 ether);
    }

    function test_multiWithdraw() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 2 ether);

        vm.startPrank(user);
        token.purchase{value: 2 * 1 ether}(2);
        vm.stopPrank();

        uint256 prevBalance = owner.balance;
        vm.startPrank(owner);
        token.withdraw();
        vm.stopPrank();

        require(owner.balance - prevBalance == 2 ether);
    }

    function test_multiWithdrawMultiUser() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 2 ether);

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

        require(owner.balance - prevBalance == 5 ether);
    }

    function test_ownerSafeMint() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(owner);
        token.safeMint(owner);
        vm.stopPrank();
    }

    function testRevert_unverifiedSafeMint() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(user);
        vm.expectRevert(IToken.SenderNotMinter.selector);
        token.safeMint(user);
        vm.stopPrank();
    }

    function test_upgrade() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(owner);
        token.upgradeTo(tokenImplUpgrade);
        vm.stopPrank();
    }

    function testRevert_upgradeNotRegistered() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSignature("InvalidUpgrade(address)", address(this))
        );
        token.upgradeTo(address(this));
        vm.stopPrank();
    }

    function testRevert_upgradeNotOwner() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        token.upgradeTo(tokenImplUpgrade);
        vm.stopPrank();
    }

    function testRevert_upgradeToAndCallNotRegistered() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSignature("InvalidUpgrade(address)", address(this))
        );
        token.upgradeToAndCall(address(this), "");
        vm.stopPrank();
    }

    function testRevert_upgradeToAndCallNotOwner() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        token.upgradeToAndCall(tokenImplUpgrade, "");
        vm.stopPrank();
    }

    function initToken() private {
        IToken.TokenInfo memory tokenInfo = IToken.TokenInfo({
            name: "Test",
            symbol: "TST",
            description: "Test description",
            fundsRecipent: owner,
            totalSupply: 10
        });

        IHTMLFixedPriceToken.SaleInfo memory saleInfo = IHTMLFixedPriceToken
            .SaleInfo({price: 1 ether, startTime: startTime, endTime: endTime});

        IHTMLRenderer.FileType[] memory imports = new IHTMLRenderer.FileType[](
            1
        );
        imports[0] = IHTMLRenderer.FileType({
            name: "Test",
            fileType: 0,
            fileSystem: fileSystem
        });

        token.initialize(
            owner,
            abi.encode(script, rendererImpl, tokenInfo, saleInfo, imports)
        );
    }
}
