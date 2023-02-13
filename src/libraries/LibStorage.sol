// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {LibHTMLRenderer} from "./LibHTMLRenderer.sol";

struct TokenStorage {
    address factory;
    address o11y;
    address feeManager;
    address ethFS;
    address fundsRecipent;
    address interactor;
    bool artistProofsMinted;
    uint256 maxSupply;
    mapping(uint256 => uint256) tokenIdToBlockDifficulty;
    mapping(address => bool) allowedMinters;
}

struct MetadataStorage {
    string symbol;
    string urlEncodedName;
    string urlEncodedDescription;
    string urlEncodedPreviewBaseURI;
    address scriptPointer;
    LibHTMLRenderer.ScriptRequest[] imports;
}

struct FixedPriceSaleInfo {
    uint64 presaleStartTime;
    uint64 presaleEndTime;
    uint112 presalePrice;
    uint64 publicStartTime;
    uint64 publicEndTime;
    uint112 publicPrice;
}

library LibStorage {
    bytes32 constant TOKEN_STORAGE_POSITION =
        keccak256("persistence.storage.token");
    bytes32 constant METADATA_STORAGE_POSITION =
        keccak256("persistence.storage.metadata");
    bytes32 constant FIXED_PRICE_SALE_STORAGE_POSITION =
        keccak256("persistence.storage.fixedPriceSale");

    function tokenStorage() internal pure returns (TokenStorage storage ts) {
        bytes32 position = TOKEN_STORAGE_POSITION;
        assembly {
            ts.slot := position
        }
    }

    function metadataStorage()
        internal
        pure
        returns (MetadataStorage storage ms)
    {
        bytes32 position = METADATA_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }

    function fixedPriceSaleInfo()
        internal
        pure
        returns (FixedPriceSaleInfo storage fps)
    {
        bytes32 position = FIXED_PRICE_SALE_STORAGE_POSITION;
        assembly {
            fps.slot := position
        }
    }
}

contract WithStorage {
    function ts() internal pure returns (TokenStorage storage) {
        return LibStorage.tokenStorage();
    }

    function ms() internal pure returns (MetadataStorage storage) {
        return LibStorage.metadataStorage();
    }

    function fixedPriceSaleInfo()
        internal
        pure
        returns (FixedPriceSaleInfo storage)
    {
        return LibStorage.fixedPriceSaleInfo();
    }
}
