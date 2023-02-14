// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibHTMLRenderer} from "../../libraries/LibHTMLRenderer.sol";

interface IInteractor {
    function getInteractionData(
        uint256 tokenId
    ) external view returns (bytes memory buffer, LibHTMLRenderer.ScriptType);

    function interact(
        address user,
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external;
}
