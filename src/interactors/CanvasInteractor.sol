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

///@notice This interactor allows a user to interact with a token if they are the owner of that token
contract CanvasInteractor is IInteractor {
    using StringsUpgradeable for uint256;

    ///@notice Token contract => TokenId => Interaction data pointer
    mapping(address => mapping(uint256 => address)) public tokenToDataPointer;

    ///@notice Token contract => Max entry bytes
    mapping(address => uint256) tokenToMaxEntryBytes;

    uint256 constant ONE_MEGABYTE_IN_BYTES = 1000000;
    uint256 constant UINT256_BYTES = 32;

    // persistence.interaction=[];
    uint256 constant SCRIPT_META_BYTES = 27;

    // [],
    uint256 constant ENTRY_META_BYTES = 3;

    // n,
    uint256 constant VALUE_META_BYTES = 2;

    function getInteractionData(
        address tokenContract,
        uint256 tokenId
    ) external view returns (bytes memory buffer, LibHTMLRenderer.ScriptType) {
        uint256 totalSupply = IToken(tokenContract).totalSupply();

        buffer = DynamicBuffer.allocate(
            ((tokenToMaxEntryBytes[tokenContract] + ENTRY_META_BYTES) *
                totalSupply) + SCRIPT_META_BYTES
        );

        DynamicBuffer.appendSafe(buffer, 'window.__userData={"');
        DynamicBuffer.appendSafe(buffer, abi.encodePacked(tokenId.toString()));
        DynamicBuffer.appendSafe(buffer, '":"');
        DynamicBuffer.appendSafe(
            buffer,
            SSTORE2.read(tokenToDataPointer[msg.sender][tokenId])
        );
        DynamicBuffer.appendSafe(buffer, '"};');

        return (buffer, LibHTMLRenderer.ScriptType.JAVASCRIPT_BASE64);
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

        uint256 dataSize = (interactionData.length + VALUE_META_BYTES) *
            UINT256_BYTES;

        if (
            dataSize >
            (ONE_MEGABYTE_IN_BYTES / IToken(msg.sender).tokenInfo().maxSupply)
        ) revert InvalidData();

        if (dataSize > tokenToMaxEntryBytes[msg.sender])
            tokenToMaxEntryBytes[msg.sender] = dataSize;

        tokenToDataPointer[msg.sender][tokenId] = SSTORE2.write(
            interactionData
        );
    }
}
