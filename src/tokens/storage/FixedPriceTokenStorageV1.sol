// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;
import {IFixedPriceToken} from "../interfaces/IFixedPriceToken.sol";
import {IHTMLRenderer} from "../../renderer/interfaces/IHTMLRenderer.sol";

abstract contract FixedPriceTokenStorageV1 {
    address scriptPointer;

    /// @notice The html renderer to use
    address htmlRenderer;

    /// @notice Required imports for the renderer
    IHTMLRenderer.FileType[] public imports;

    /// @notice Sales info for token purchases
    IFixedPriceToken.SaleInfo public saleInfo;
}
