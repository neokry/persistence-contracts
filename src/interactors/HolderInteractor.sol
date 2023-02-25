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

    // window.__rt_user=%7B%2210000%22:%22%22%7D;
    uint256 constant SCRIPT_META_BYTES = 42;

    ///@notice Token contract => Token Id => Interaction data pointer
    mapping(address => mapping(uint256 => address)) public tokenToDataPointer;

    // [[[ View Functions ]]]

    function isValidInteraction(
        address user,
        address tokenContract,
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external view returns (bool) {
        return _isValidInteraction(user, tokenContract, tokenId);
    }

    function getInteractionData(
        address tokenContract,
        uint256 tokenId
    ) external view returns (bytes memory buffer, LibHTMLRenderer.ScriptType) {
        bytes memory data = SSTORE2.read(
            tokenToDataPointer[tokenContract][tokenId]
        );

        buffer = DynamicBuffer.allocate(
            _sizeForBase64Encoding(data.length) + SCRIPT_META_BYTES
        );

        DynamicBuffer.appendSafe(buffer, "window.__rt_user=%7B%22");
        DynamicBuffer.appendSafe(buffer, bytes(tokenId.toString()));
        DynamicBuffer.appendSafe(buffer, "%22:%22");
        DynamicBuffer.appendSafeBase64(
            buffer,
            SSTORE2.read(tokenToDataPointer[tokenContract][tokenId]),
            false,
            false
        );
        DynamicBuffer.appendSafe(buffer, "%22%7D;");

        return (buffer, LibHTMLRenderer.ScriptType.JAVASCRIPT_URL_ENCODED);
    }

    /// [[[ Interaction Function ]]]

    /// @notice This function returns true if the user is the owner of the token
    function interact(
        address user,
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external {
        if (!_isValidInteraction(user, msg.sender, tokenId))
            revert InvalidInteraction();

        tokenToDataPointer[msg.sender][tokenId] = SSTORE2.write(
            interactionData
        );

        emit InteractionDataUpdated(user, msg.sender, tokenId, interactionData);
    }

    // [[[ Private Functions ]]]

    function _isValidInteraction(
        address user,
        address tokenContract,
        uint256 tokenId
    ) internal view returns (bool) {
        return user == IERC721Upgradeable(tokenContract).ownerOf(tokenId);
    }

    function _sizeForBase64Encoding(
        uint256 value
    ) internal pure returns (uint256) {
        unchecked {
            return 4 * ((value + 2) / 3);
        }
    }
}
