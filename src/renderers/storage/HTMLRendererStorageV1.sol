// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

abstract contract HTMLRendererStorageV1 {
    uint8 constant FILE_TYPE_JAVASCRIPT_PLAINTEXT = 0;
    uint8 constant FILE_TYPE_JAVASCRIPT_BASE64 = 1;
    uint8 constant FILE_TYPE_JAVASCRIPT_GZIP = 2;
}
