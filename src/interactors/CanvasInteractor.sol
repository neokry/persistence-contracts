// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import {LibHTMLRenderer} from "../libraries/LibHTMLRenderer.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {IInteractor} from "./interfaces/IInteractor.sol";
import {IToken} from "../tokens/interfaces/IToken.sol";
import "forge-std/console2.sol";

///@notice This interactor allows a token owner to interact and aggregates all interaction data on view
contract CanvasInteractor is IInteractor {
    using StringsUpgradeable for uint256;

    ///@notice Token contract => TokenId => Interaction data pointer
    mapping(address => mapping(uint256 => address)) public tokenToDataPointer;

    ///@notice Token contract => Max entry bytes
    mapping(address => uint256) tokenToMaxEntryBytes;

    uint256 constant ONE_MEGABYTE_IN_BYTES = 1000000;
    uint256 constant UINT256_BYTES = 32;

    // window.__rt_user=%7B%7D;
    uint256 constant SCRIPT_META_BYTES = 24;

    // %2210000%22:%22%22,
    uint256 constant ENTRY_META_BYTES = 19;

    // [[[ View Functions ]]]

    function isValidInteraction(
        address user,
        address tokenContract,
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external view returns (bool) {
        return
            _isValidInteraction(user, tokenContract, tokenId, interactionData);
    }

    function getInteractionData(
        address tokenContract,
        uint256 tokenId
    ) external view returns (bytes memory buffer, LibHTMLRenderer.ScriptType) {
        uint256 totalSupply = IToken(tokenContract).totalSupply();

        buffer = DynamicBuffer.allocate(
            ((_sizeForBase64Encoding(tokenToMaxEntryBytes[tokenContract]) +
                ENTRY_META_BYTES) * totalSupply) + SCRIPT_META_BYTES
        );

        DynamicBuffer.appendSafe(buffer, "window.__rt_user=%7B");

        uint256 i = 0;

        do {
            if (i != 0) DynamicBuffer.appendSafe(buffer, ",");
            DynamicBuffer.appendSafe(buffer, "%22");
            DynamicBuffer.appendSafe(buffer, bytes(tokenId.toString()));
            DynamicBuffer.appendSafe(buffer, "%22:%22");
            DynamicBuffer.appendSafeBase64(
                buffer,
                SSTORE2.read(tokenToDataPointer[msg.sender][tokenId]),
                false,
                false
            );
            DynamicBuffer.appendSafe(buffer, "%22");
        } while (++i < totalSupply);

        DynamicBuffer.appendSafe(buffer, "%7D;");

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
        if (!_isValidInteraction(user, msg.sender, tokenId, interactionData))
            revert InvalidInteraction();

        if (interactionData.length > tokenToMaxEntryBytes[msg.sender])
            tokenToMaxEntryBytes[msg.sender] = interactionData.length;

        tokenToDataPointer[msg.sender][tokenId] = SSTORE2.write(
            interactionData
        );

        emit InteractionDataUpdated(user, msg.sender, tokenId, interactionData);
    }

    // [[[ Private Functions ]]]

    function _isValidInteraction(
        address user,
        address tokenContract,
        uint256 tokenId,
        bytes calldata interactionData
    ) internal view returns (bool) {
        uint256 maxDataPerInteraction = ONE_MEGABYTE_IN_BYTES /
            IToken(tokenContract).tokenInfo().maxSupply;
        return
            user == IERC721Upgradeable(tokenContract).ownerOf(tokenId) &&
            (interactionData.length < maxDataPerInteraction);
    }

    function _sizeForBase64Encoding(
        uint256 value
    ) internal pure returns (uint256) {
        unchecked {
            return 4 * ((value + 2) / 3);
        }
    }
}
