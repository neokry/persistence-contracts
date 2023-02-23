// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {TokenFactory} from "../src/TokenFactory.sol";

import {IInteractor} from "../src/interactors/interfaces/IInteractor.sol";
import {FixedPriceTokenUtils} from "./utils/FixedPriceTokenUtils.sol";
import {HolderInteractor} from "../src/interactors/HolderInteractor.sol";

contract HolderInteractorTest is Test, FixedPriceTokenUtils {
    address interactor;

    function test_interact() public {
        init();
        vm.startPrank(owner);
        token.safeMint(owner);

        bytes
            memory interactionData = hex"30783762323236323635363137343432373537343734366636653733323233613562356233313263333032633331326333303564326335623330326333313263333032633331356432633562333132633330326333313263333035643263356233303263333132633331326333303564326335623331326333313263333032633330356432633562333032633331326333303263333135643263356233313263333032633331326333303564356432633232373336633639363436353732373332323361356235623562333032653331326333303265333132633330326533313263333032653331326333303265333132633330326533313263333032653331356432633562333032653331326333303265333232633330326533343263333032653336326333303265333732633330326533383263333032653339356435643263356235623330326533313263333032653331326333303265333132633330326533313263333032653331326333303265333132633330326533313564326335623330326533343263333032653335326333303265333632633330326533343263333032653337326333303265333532633330326533363564356432633562356233303263333032633330326333303263333032633330326333303564326335623330326533393263333032653338326333303265333732633330326533363263333032653334326333303265333332633330326533323564356432633562356233303265333432633330326533343263333032653334326333303265333732633330326533373263333032653337326333303265333235643263356233303265333232633330326533363263333032653332326333303265333632633330326533383263333032653332326333303265333335643564356432633232373436353664373036663232336133343330333037643030303030303030303030303030000000000000000000000000000000000000000000000000000000000000";

        emit log("initalData");
        emit log(string(interactionData));

        token.interact(0, interactionData, new bytes(0));
        vm.stopPrank();

        (bytes memory newData, ) = IInteractor(interactor).getInteractionData(
            address(token),
            0
        );

        emit log("userData");
        emit log(string(newData));

        /*
        require(
            keccak256(newData) == keccak256('window.__userData={0:"123"};'),
            "invalid data"
        );
        */
    }

    function testFork_interact() public {
        initFork();
        vm.startPrank(owner);

        token.safeMint(owner);

        uint256 i = 0;
        uint256 length = 100;

        bytes memory interactionData = new bytes(123);
        token.interact(0, interactionData, new bytes(0));
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

        interactor = address(new HolderInteractor());
        vm.prank(owner);
        token.setInteractor(interactor);
    }

    function initFork() private {
        _setUp();

        vm.prank(factory);
        _initToken(10);

        interactor = address(new HolderInteractor());
        vm.prank(owner);
        token.setInteractor(interactor);
    }
}
