// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";

import {IInteractor} from "../src/interactors/interfaces/IInteractor.sol";
import {FixedPriceTokenUtils} from "./utils/FixedPriceTokenUtils.sol";
import {CanvasInteractor} from "../src/interactors/CanvasInteractor.sol";

contract CanvasInteractorTest is Test, FixedPriceTokenUtils {
    address interactor;

    function test_interact() public {
        init();
        vm.startPrank(owner);
        token.safeMint(owner);

        bytes memory interactionData = new bytes(123);

        token.interact(0, interactionData, new bytes(0));
        vm.stopPrank();

        (bytes memory newData, ) = IInteractor(interactor).getInteractionData(
            address(token),
            0
        );

        /*
        require(
            keccak256(newData) == keccak256("window.__rt_user=[[1n],[]];"),
            "invalid data"
        );
        */
    }

    function testFork_interactSingle() public {
        initFork();
        vm.startPrank(owner);

        bytes memory interactionData = new bytes(123);

        token.interact(0, interactionData, new bytes(0));

        vm.stopPrank();

        token.tokenURI(0);
    }

    function testFork_interactLarge() public {
        initFork();
        vm.startPrank(owner);

        uint256 tokenSize = 99;
        uint256 dataSize = 139;
        uint256 i = 0;
        uint256 n = 0;

        do {
            token.safeMint(owner);

            n = 0;
            bytes
                memory interactionData = hex"7b2262656174427574746f6e73223a5b5b312c302c312c305d2c5b302c312c302c315d2c5b312c302c312c305d2c5b302c312c312c305d2c5b312c312c302c305d2c5b302c312c302c315d2c5b312c302c312c305d5d2c22736c6964657273223a5b5b5b302e312c302e312c302e312c302e312c302e312c302e312c302e315d2c5b302e312c302e322c302e342c302e362c302e372c302e382c302e395d5d2c5b5b302e312c302e312c302e312c302e312c302e312c302e312c302e315d2c5b302e342c302e352c302e362c302e342c302e372c302e352c302e365d5d2c5b5b302c302c302c302c302c302c305d2c5b302e392c302e382c302e372c302e362c302e342c302e332c302e325d5d2c5b5b302e342c302e342c302e342c302e372c302e372c302e372c302e325d2c5b302e322c302e362c302e322c302e362c302e382c302e322c302e335d5d5d2c2274656d706f223a3430307d";

            token.interact(i, interactionData, new bytes(0));
        } while (++i < tokenSize);

        vm.stopPrank();

        token.tokenURI(0);
    }

    function testRevert_invalidInteraction() public {
        init();
        vm.prank(owner);
        token.safeMint(owner);

        bytes memory interactionData = new bytes(123);

        vm.prank(user);
        vm.expectRevert(IInteractor.InvalidInteraction.selector);
        token.interact(0, interactionData, new bytes(0));
    }

    function init() private {
        _setUp();

        vm.prank(factory);
        _initToken(10);

        interactor = address(new CanvasInteractor());
        vm.prank(owner);
        token.setInteractor(interactor);
    }

    function initFork() private {
        _setUp();

        vm.prank(factory);
        _initToken(140);

        interactor = address(new CanvasInteractor());
        vm.prank(owner);
        token.setInteractor(interactor);
    }
}
