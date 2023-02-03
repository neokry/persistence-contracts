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
import {MockImpl} from "./utils/mocks/MockImpl.sol";
import {ITokenFactory} from "../src/interfaces/ITokenFactory.sol";

contract TokenFactoryTest is Test {
    TokenFactory factory;
    address tokenImpl = address(1);
    address tokenUpgrade = address(2);
    address owner = address(3);
    address notOwner = address(4);

    function setUp() public {
        vm.prank(owner);
        factory = new TokenFactory();
    }

    function test_addDeployment() public {
        vm.prank(owner);
        factory.registerDeployment(tokenImpl);
        require(factory.isValidDeployment(tokenImpl));
    }

    function testRevert_addDeploymentNotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.registerDeployment(tokenImpl);
    }

    function test_removeDeployment() public {
        vm.startPrank(owner);
        factory.registerDeployment(tokenImpl);
        factory.unregisterDeployment(tokenImpl);
        vm.stopPrank();
        require(!factory.isValidDeployment(tokenImpl));
    }

    function testRevert_removeDeploymentNotOwner() public {
        vm.prank(owner);
        factory.registerDeployment(tokenImpl);

        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.unregisterDeployment(tokenImpl);
    }

    function test_addUpgrade() public {
        vm.prank(owner);
        factory.registerUpgrade(tokenImpl, tokenUpgrade);
        require(factory.isValidUpgrade(tokenImpl, tokenUpgrade));
    }

    function testRevert_addUpgradeNotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.registerUpgrade(tokenImpl, tokenUpgrade);
    }

    function test_removeUpgrade() public {
        vm.startPrank(owner);
        factory.registerUpgrade(tokenImpl, tokenUpgrade);
        factory.unregisterUpgrade(tokenImpl, tokenUpgrade);
        vm.stopPrank();
        require(!factory.isValidUpgrade(tokenImpl, tokenUpgrade));
    }

    function testRevert_removeUpgradeNotOwner() public {
        vm.prank(owner);
        factory.registerUpgrade(tokenImpl, tokenUpgrade);

        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.unregisterUpgrade(tokenImpl, tokenUpgrade);
    }

    function test_create() public {
        vm.startPrank(owner);

        address mockImpl = address(new MockImpl());

        factory.registerDeployment(mockImpl);
        factory.create(mockImpl, abi.encode("test"));
        vm.stopPrank();
    }

    function testRevert_createNotDeployed() public {
        vm.startPrank(owner);

        address mockImpl = address(new MockImpl());

        vm.expectRevert(
            abi.encodeWithSignature("NotDeployed(address)", mockImpl)
        );
        factory.create(mockImpl, abi.encode("test"));
        vm.stopPrank();
    }
}
