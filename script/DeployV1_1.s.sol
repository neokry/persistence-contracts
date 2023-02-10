// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {FeeManager} from "../src/FeeManager.sol";

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

        address factory = _getKey("Factory");
        address o11y = _getKey("Observability");
        address ethfs = address(0);

        console2.log("~~~~~~~~~~ Factory ADDRESS ~~~~~~~~~~~");
        console2.logAddress(factory);

        console2.log("~~~~~~~~~~ Observability ADDRESS ~~~~~~~~~~~");
        console2.logAddress(o11y);

        vm.startBroadcast(deployerPrivateKey);

        address feeManager = address(
            new FeeManager(1000, 0x04bfb0034F24E424489F566f32D1f57647469f9E)
        );

        address tokenImpl = address(
            new FixedPriceToken(factory, o11y, feeManager, ethfs)
        );

        vm.stopBroadcast();

        string memory filePath = string(
            abi.encodePacked("deploys/", chainID.toString(), ".version1_1.txt")
        );

        vm.writeLine(
            filePath,
            string(
                abi.encodePacked(
                    "FixedPriceToken Upgrade implementation: ",
                    addressToString(tokenImpl)
                )
            )
        );

        vm.writeLine(
            filePath,
            string(
                abi.encodePacked("FeeManager: ", addressToString(feeManager))
            )
        );
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
