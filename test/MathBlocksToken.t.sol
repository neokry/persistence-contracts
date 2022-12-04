// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MathBlocksToken/MathBlocksToken.sol";
import "../src/Observability/Observability.sol";

contract MathBlocksTokenTest is Test {
    MathBlocksToken token;
    address factory = address(1);
    address owner = address(2);
    address user = address(3);
    address otherUser = address(4);
    address htmlRenderer = address(5);
    uint256 endTime = 0;

    function setUp() public {
        address o11y = address(new Observability());
        token = new MathBlocksToken(factory, o11y, htmlRenderer);
        endTime = block.timestamp + 2 days;
    }

    function test_onlyFactoryCanInitilize() public {
        vm.prank(factory);
        initToken();
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

        vm.deal(user, 2 ether);

        vm.startPrank(user);
        token.purchase{value: 2 * 1 ether}(2);
        vm.stopPrank();
    }

    function testRevert_purchaseSaleEnded() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 1 ether);
        vm.warp(endTime + 1 seconds);

        vm.startPrank(user);
        vm.expectRevert(IMathBlocksToken.SaleHasEnded.selector);
        token.purchase(1);
        vm.stopPrank();
    }

    function testRevert_purchaseInvalidPrice() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 1 ether);

        vm.startPrank(user);
        vm.expectRevert(IMathBlocksToken.InvalidPrice.selector);
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
        vm.expectRevert(IMathBlocksToken.SenderNotMinter.selector);
        token.safeMint(user);
        vm.stopPrank();
    }

    function initToken() private {
        IMathBlocksToken.TokenInfo memory info = IMathBlocksToken.TokenInfo({
            name: "Test",
            symbol: "TST",
            description: "Test Description",
            script: "var i = 1;",
            price: 1 ether,
            fundsRecipent: owner,
            endsAtTimestamp: endTime
        });
        token.initialize(owner, info);
    }
}
