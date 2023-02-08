// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {ERC1967Proxy} from "../vendor/proxy/ERC1967Proxy.sol";

contract HTMLRendererProxy is ERC1967Proxy {
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}
}
