// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IInteractor} from "./interfaces/IInteractor.sol";
import {LibHTMLRenderer} from "../libraries/LibHTMLRenderer.sol";

import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

///@notice This interactor allows a user to interact with a token if they are the owner of that token
contract HolderInteractor is IInteractor {
    using StringsUpgradeable for uint256;

    uint256 constant UINT256_BYTES = 32;

    // persistence.interaction=[];
    uint256 constant SCRIPT_META_BYTES = 27;

    // n,
    uint256 constant VALUE_META_BYTES = 2;

    ///@notice Token contract => Token Id => Interaction data pointer
    mapping(address => mapping(uint256 => address)) public tokenToDataPointer;

    function getInteractionData(
        address tokenContract,
        uint256 tokenId
    ) external view returns (bytes memory buffer, LibHTMLRenderer.ScriptType) {
        bytes memory data = SSTORE2.read(
            tokenToDataPointer[tokenContract][tokenId]
        );

        buffer = DynamicBuffer.allocate(data.length + SCRIPT_META_BYTES);

        DynamicBuffer.appendSafe(buffer, 'window.__userData={"');
        DynamicBuffer.appendSafe(buffer, bytes(tokenId.toString()));
        DynamicBuffer.appendSafe(buffer, '":"');
        DynamicBuffer.appendSafe(
            buffer,
            SSTORE2.read(tokenToDataPointer[tokenContract][tokenId])
        );
        DynamicBuffer.appendSafe(buffer, '"};');

        return (buffer, LibHTMLRenderer.ScriptType.JAVASCRIPT_PLAINTEXT);
    }

    /// @notice This function returns true if the user is the owner of the token
    function interact(
        address user,
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external {
        if (user != IERC721Upgradeable(msg.sender).ownerOf(tokenId))
            revert InvalidInteraction();

        tokenToDataPointer[msg.sender][tokenId] = SSTORE2.write(
            abi.encodePacked(interactionData)
        );
    }
}
