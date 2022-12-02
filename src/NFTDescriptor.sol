// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Base64} from "base64-sol/base64.sol";

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        string animation_url;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(
        TokenURIParams memory params
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                params.name,
                                '", "description":"',
                                params.description,
                                '", "animation_url": "',
                                params.animation_url,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
