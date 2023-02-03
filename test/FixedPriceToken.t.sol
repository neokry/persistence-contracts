// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {IFixedPriceToken} from "../src/tokens/interfaces/IFixedPriceToken.sol";
import {HTMLRenderer} from "../src/renderer/HTMLRenderer.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {Observability} from "../src/observability/Observability.sol";
import {IHTMLRenderer} from "../src/renderer/interfaces/IHTMLRenderer.sol";
import {TokenProxy} from "../src/TokenProxy.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {ITokenFactory} from "../src/interfaces/ITokenFactory.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {SpecificTokenHolderInteractor} from "../src/interactors/SpecificTokenHolderInteractor.sol";
import {GeneralTokenHolderInteractor} from "../src/interactors/GeneralTokenHolderInteractor.sol";
import {FeeManager} from "../src/FeeManager.sol";

contract FixedPriceTokenTest is Test {
    FixedPriceToken token;
    address factory = address(1);
    address owner = address(2);
    address user = address(3);
    address otherUser = address(4);
    address rendererImpl = address(5);
    address interactor = address(6);
    address fileSystem = address(7);
    address treasury = address(8);
    address tokenImplUpgrade;
    uint64 startTime = 0;
    uint64 endTime = 0;
    string script = "let x = 1;";
    string previewBaseURI = "https://example.com/";

    using StringsUpgradeable for uint256;

    function setUp() public {
        address o11y = address(new Observability());
        TokenFactory tokenFactory = new TokenFactory();
        factory = address(tokenFactory);
        address feeManager = address(new FeeManager(1000, treasury));

        address tokenImpl = address(
            new FixedPriceToken(factory, o11y, feeManager)
        );

        tokenImplUpgrade = address(
            new FixedPriceToken(factory, o11y, feeManager)
        );
        rendererImpl = address(new HTMLRenderer(factory));
        interactor = address(new SpecificTokenHolderInteractor());

        tokenFactory.registerDeployment(tokenImpl);
        tokenFactory.registerDeployment(rendererImpl);

        tokenFactory.registerUpgrade(tokenImpl, tokenImplUpgrade);

        token = FixedPriceToken(address(new TokenProxy(tokenImpl, "")));

        startTime = uint64(block.timestamp);
        endTime = uint64(block.timestamp + 2 days);
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

        (
            uint16 artistProofCount,
            uint256 saleStart,
            uint256 saleEnd,
            uint256 price
        ) = token.saleInfo();

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
        require(artistProofCount == 1, "Invalid amount of proofs");
        require(token.totalSupply() == 1, "Proofs not minted");
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

        vm.deal(user, 9 ether);

        vm.startPrank(user);
        token.purchase{value: 9 * 1 ether}(9);
        vm.stopPrank();
    }

    function test_purchaseZero() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(user);
        vm.expectRevert(IFixedPriceToken.InvalidAmount.selector);
        token.purchase(0);
        vm.stopPrank();
    }

    function testRevert_soldOut() public {
        vm.prank(factory);
        initToken();

        vm.deal(user, 11 ether);

        vm.startPrank(user);
        vm.expectRevert(IFixedPriceToken.SoldOut.selector);
        token.purchase{value: 11 * 1 ether}(11);
        vm.stopPrank();
    }

    function testRevert_purchaseSaleNotActive() public {
        vm.prank(factory);
        initToken();

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
        initToken();

        vm.deal(user, 1 ether);

        vm.startPrank(user);
        vm.expectRevert(IFixedPriceToken.InvalidPrice.selector);
        token.purchase(1);
        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.prank(factory);
        initToken();

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
        initToken();

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
        initToken();

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

    function testGeneratePreviewURI() public {
        vm.prank(factory);
        initToken();

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

    function testNoInteractor() public {
        vm.prank(factory);
        initToken();

        vm.startPrank(owner);
        token.setInteractor(address(0));

        vm.expectRevert(IFixedPriceToken.InteractorNotSet.selector);
        token.setInteractionState(0, new bytes(0), "123");
        vm.stopPrank();
    }

    function testNoInteraction() public {
        vm.prank(factory);
        initToken();

        require(
            keccak256(abi.encodePacked(token.getInteractionState(0))) ==
                keccak256("")
        );
    }

    function testSpecificInteractor() public {
        vm.prank(factory);
        initToken();

        vm.prank(owner);
        token.safeMint(user);

        string memory initalState = "123";

        vm.startPrank(user);
        token.setInteractionState(1, new bytes(0), initalState);
        vm.stopPrank();

        string memory newState = token.getInteractionState(1);
        require(
            keccak256(abi.encodePacked(initalState)) ==
                keccak256(abi.encodePacked(newState)),
            "State missmatch"
        );
    }

    function testRevert_SpecificInteractorNotHolder() public {
        vm.prank(factory);
        initToken();

        string memory initalState = "123";

        vm.startPrank(user);
        vm.expectRevert(IFixedPriceToken.InvalidInteraction.selector);
        token.setInteractionState(0, new bytes(0), initalState);
        vm.stopPrank();
    }

    function testRevert_SpecificInteractorInvalidTokenId() public {
        vm.prank(factory);
        initToken();

        string memory initalState = "123";

        vm.startPrank(user);
        vm.expectRevert(IFixedPriceToken.InvalidTokenId.selector);
        token.setInteractionState(1, new bytes(0), initalState);
        vm.stopPrank();
    }

    function testSetInteractor() public {
        vm.prank(factory);
        initToken();

        vm.prank(owner);
        token.setInteractor(address(10));
    }

    function testGeneralInteractor() public {
        vm.prank(factory);
        initToken();

        vm.prank(owner);
        token.safeMint(user);

        GeneralTokenHolderInteractor generalInteractor = new GeneralTokenHolderInteractor();

        vm.prank(owner);
        token.setInteractor(address(generalInteractor));

        string memory initalState = "123";
        bytes memory data = generalInteractor.getValidationData(0);

        vm.startPrank(owner);
        token.setInteractionState(1, data, initalState);
        vm.stopPrank();
    }

    function testRevert_GeneralInteractorUserNotHolder() public {
        vm.prank(factory);
        initToken();

        vm.prank(owner);
        token.safeMint(user);

        GeneralTokenHolderInteractor generalInteractor = new GeneralTokenHolderInteractor();

        vm.prank(owner);
        token.setInteractor(address(generalInteractor));

        string memory initalState = "123";
        bytes memory data = generalInteractor.getValidationData(0);

        vm.startPrank(otherUser);
        vm.expectRevert(IFixedPriceToken.InvalidInteraction.selector);
        token.setInteractionState(1, data, initalState);
        vm.stopPrank();
    }

    function testRevert_GeneralInteractorInvalidTokenIdForCheck() public {
        vm.prank(factory);
        initToken();

        GeneralTokenHolderInteractor generalInteractor = new GeneralTokenHolderInteractor();

        vm.prank(owner);
        token.setInteractor(address(generalInteractor));

        string memory initalState = "123";
        bytes memory data = generalInteractor.getValidationData(1);

        vm.startPrank(user);
        vm.expectRevert("ERC721: invalid token ID");
        token.setInteractionState(0, data, initalState);
        vm.stopPrank();
    }

    function testRevert_GeneralInteractorInvalidTokenIdForInteraction() public {
        vm.prank(factory);
        initToken();

        GeneralTokenHolderInteractor generalInteractor = new GeneralTokenHolderInteractor();

        vm.prank(owner);
        token.setInteractor(address(generalInteractor));

        string memory initalState = "123";
        bytes memory data = generalInteractor.getValidationData(0);

        vm.startPrank(owner);
        vm.expectRevert(IFixedPriceToken.InvalidTokenId.selector);
        token.setInteractionState(1, data, initalState);
        vm.stopPrank();
    }

    function initToken() private {
        IToken.TokenInfo memory tokenInfo = IToken.TokenInfo({
            name: "Test",
            symbol: "TST",
            description: "Test description",
            fundsRecipent: owner,
            maxSupply: 10
        });

        IFixedPriceToken.SaleInfo memory saleInfo = IFixedPriceToken.SaleInfo({
            artistProofCount: 1,
            price: 1 ether,
            startTime: startTime,
            endTime: endTime
        });

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
            abi.encode(
                script,
                previewBaseURI,
                rendererImpl,
                interactor,
                tokenInfo,
                saleInfo,
                imports
            )
        );
    }
}
