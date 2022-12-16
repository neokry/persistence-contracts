// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UUPS} from "../../../src/lib/proxy/UUPS.sol";

contract MockImpl is UUPS {
    function initialize(address owner, bytes calldata data) public {}

    function _authorizeUpgrade(address _newImpl) internal view override {}
}
