// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import {LibHTMLRenderer} from "../libraries/LibHTMLRenderer.sol";

import {IInteractor} from "./interfaces/IInteractor.sol";
import {IToken} from "../tokens/interfaces/IToken.sol";

///@notice This interactor allows a user to interact with a token if they are the owner of that token
contract CanvasInteractor is IInteractor {
    error InvalidInteraction();
    error DataTooLarge();

    ///@notice Token contract => TokenId => Interaction data pointer
    mapping(address => mapping(uint256 => address)) public tokenToDataPointer;

    ///@notice Token contract => Max entry bytes
    mapping(address => uint256) tokenToMaxEntryBytes;

    uint256 constant ONE_HALF_MEGABYTE_IN_BYTES = 500000;
    uint256 constant TOTAL_META_BYTES = 27;
    uint256 constant COMMA_BYTES = 1;

    function getInteractionData(
        uint256 tokenId
    ) external view returns (bytes memory buffer, LibHTMLRenderer.ScriptType) {
        uint256 totalSupply = IToken(msg.sender).totalSupply();

        buffer = DynamicBuffer.allocate(
            ((tokenToMaxEntryBytes[msg.sender] + COMMA_BYTES) * totalSupply) +
                TOTAL_META_BYTES
        );
        uint256 i = 0;

        DynamicBuffer.appendSafe(buffer, 'persistence.interaction="');

        unchecked {
            do {
                if (tokenToDataPointer[msg.sender][i] != address(0)) {
                    DynamicBuffer.appendSafe(
                        buffer,
                        SSTORE2.read(tokenToDataPointer[msg.sender][i])
                    );
                }
                DynamicBuffer.appendSafe(buffer, ",");
            } while (++i < totalSupply);
        }

        DynamicBuffer.appendSafe(buffer, '";');

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

        if (
            interactionData.length >
            (ONE_HALF_MEGABYTE_IN_BYTES /
                IToken(msg.sender).tokenInfo().maxSupply)
        ) revert DataTooLarge();

        if (interactionData.length > tokenToMaxEntryBytes[user])
            tokenToMaxEntryBytes[user] = interactionData.length;

        tokenToDataPointer[msg.sender][tokenId] = SSTORE2.write(
            interactionData
        );
    }
}
