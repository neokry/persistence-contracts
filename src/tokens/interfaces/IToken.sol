//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibHTMLRenderer} from "../../libraries/LibHTMLRenderer.sol";

interface IToken {
    struct TokenInfo {
        address factory;
        address o11y;
        address feeManager;
        address fundsRecipent;
        address interactor;
        bool artistProofsMinted;
        uint256 maxSupply;
    }

    struct MetadataInfo {
        string symbol;
        string urlEncodedName;
        string urlEncodedDescription;
        string urlEncodedPreviewBaseURI;
        address scriptPointer;
        LibHTMLRenderer.ScriptRequest[] imports;
    }

    error FactoryMustInitilize();
    error SenderNotMinter();
    error FundsSendFailure();
    error MaxSupplyReached();
    error ProofsMinted();

    /// @notice returns the total supply of tokens
    function totalSupply() external view returns (uint256);

    function tokenInfo() external view returns (TokenInfo memory info);

    function metadataInfo() external view returns (MetadataInfo memory info);

    /// @notice withdraws the funds from the contract
    function withdraw() external returns (bool);

    /// @notice mint a token for the given address
    function safeMint(address to) external;

    /// @notice sets the funds recipent for token funds
    function setFundsRecipent(address fundsRecipent) external;

    /// @notice sets the minter status for the given user
    function setMinter(address user, bool isAllowed) external;
}
