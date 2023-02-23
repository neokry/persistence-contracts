// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibHTMLRenderer} from "../../libraries/LibHTMLRenderer.sol";

interface IInteractor {
    error InvalidInteraction();
    error InvalidData();

    function getInteractionData(
        address tokenContract,
        uint256 tokenId
    ) external view returns (bytes memory buffer, LibHTMLRenderer.ScriptType);

    function interact(
        address user,
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external;
}
