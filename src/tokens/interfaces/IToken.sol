//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IHTMLRenderer} from "../../renderer/interfaces/IHTMLRenderer.sol";

interface IToken {
    struct TokenInfo {
        address factory;
        address o11y;
        address feeManager;
        address fundsRecipent;
        address htmlRenderer;
        address interactor;
        bool artistProofsMinted;
        uint256 maxSupply;
    }

    struct MetadataInfo {
        string name;
        string symbol;
        string description;
        string previewBaseURI;
        address scriptPointer;
        IHTMLRenderer.ExternalScript[] imports;
    }

    error FactoryMustInitilize();
    error SenderNotMinter();
    error FundsSendFailure();
    error MaxSupplyReached();
    error ProofsMinted();

    /// @notice returns the total supply of tokens
    function totalSupply() external returns (uint256);

    /// @notice withdraws the funds from the contract
    function withdraw() external returns (bool);

    /// @notice mint a token for the given address
    function safeMint(address to) external;

    /// @notice sets the funds recipent for token funds
    function setFundsRecipent(address fundsRecipent) external;

    /// @notice sets the minter status for the given user
    function setMinter(address user, bool isAllowed) external;
}
