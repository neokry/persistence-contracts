// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {TokenFactory} from "../src/TokenFactory.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {IFixedPriceToken} from "../src/tokens/interfaces/IFixedPriceToken.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {IHTMLRenderer} from "../src/renderer/interfaces/IHTMLRenderer.sol";
import {HTMLRendererStorageV1} from "../src/renderer/storage/HTMLRendererStorageV1.sol";

contract Deploy is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address factory = 0x0567758833057088e7f0DB522376343b54Bd17FA;

        vm.startBroadcast(deployerPrivateKey);

        TokenFactory factoryInstance = TokenFactory(factory);

        address o11y = address(factoryInstance.o11y());

        FixedPriceToken impl = new FixedPriceToken(address(factory), o11y);
        factoryInstance.registerDeployment(address(impl));

        console2.log("impl:");
        console2.log(address(impl));

        vm.stopBroadcast();
    }
}
