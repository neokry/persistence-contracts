// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {HolderInteractor} from "../src/interactors/HolderInteractor.sol";

contract Deploy is Script {
    using Strings for uint256;

    string configFile;

    function _getKey(string memory key) internal view returns (address result) {
        (result) = abi.decode(vm.parseJson(configFile, key), (address));
    }

    function run() public {
        uint256 chainID = vm.envUint("CHAIN_ID");
        console.log("CHAIN_ID", chainID);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        configFile = vm.readFile(
            string.concat("./addresses/", Strings.toString(chainID), ".json")
        );

        vm.startBroadcast(deployerPrivateKey);

        address holderInteractor = address(new HolderInteractor());

        //address canvasInteractor = address(new CanvasInteractor());

        vm.stopBroadcast();

        string memory filePath = string(
            abi.encodePacked("deploys/", chainID.toString(), ".interactors.txt")
        );

        vm.writeLine(
            filePath,
            string(
                abi.encodePacked(
                    "HolderInteractor: ",
                    addressToString(holderInteractor)
                )
            )
        );

        /*
        vm.writeLine(
            filePath,
            string(
                abi.encodePacked(
                    "CanvasInteractor: ",
                    addressToString(canvasInteractor)
                )
            )
        );
        */
    }

    function addressToString(
        address _addr
    ) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(_addr)) / (2 ** (8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", string(s)));
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
