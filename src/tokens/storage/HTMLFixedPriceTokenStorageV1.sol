// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import {IHTMLFixedPriceToken} from "../interfaces/IHTMLFixedPriceToken.sol";
import {IHTMLRenderer} from "../../renderers/interfaces/IHTMLRenderer.sol";

abstract contract HTMLFixedPriceTokenStorageV1 {
    /// @notice The users script to be renderered
    string script;

    /// @notice The html renderer to use
    address htmlRenderer;

    /// @notice Required imports for the renderer
    IHTMLRenderer.FileType[] public imports;

    /// @notice Sales info for token purchases
    IHTMLFixedPriceToken.SaleInfo public saleInfo;
}
