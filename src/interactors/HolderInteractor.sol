// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IInteractor} from "./interfaces/IInteractor.sol";
import {LibHTMLRenderer} from "../libraries/LibHTMLRenderer.sol";

import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

///@notice This interactor allows a user to interact with a token if they are the owner of that token
contract HolderInteractor is IInteractor {
    error InvalidInteraction();

    ///@notice Token contract => Token Id => Interaction data pointer
    mapping(address => mapping(uint256 => address)) public tokenToDataPointer;

    function getInteractionData(
        uint256 tokenId
    ) external view returns (bytes memory, LibHTMLRenderer.ScriptType) {
        return (
            SSTORE2.read(tokenToDataPointer[msg.sender][tokenId]),
            LibHTMLRenderer.ScriptType.JAVASCRIPT_PLAINTEXT
        );
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
            interactionData
        );
    }
}
