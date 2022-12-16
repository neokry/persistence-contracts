// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Base64} from "base64-sol/base64.sol";
import {IFileSystemAdapter} from "../fileSystemAdapters/interfaces/IFileSystemAdapter.sol";
import {IHTMLRenderer} from "./interfaces/IHTMLRenderer.sol";
import {HTMLRendererStorageV1} from "./storage/HTMLRendererStorageV1.sol";
import {UUPS} from "../lib/proxy/UUPS.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {VersionedContract} from "../VersionedContract.sol";

contract HTMLRenderer is
    IHTMLRenderer,
    HTMLRendererStorageV1,
    UUPS,
    Ownable2StepUpgradeable,
    VersionedContract
{
    address factory;

    constructor(address _factory) {
        factory = _factory;
    }

    /**
     * @notice Construct an html URI.
     */
    function generateURI(
        FileType[] calldata imports,
        string calldata script
    ) public view returns (string memory) {
        return
            string.concat(
                "data:text/html;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '<html><head><style type="text/css"> *{padding: 0; margin: 0;}</style>',
                            generateManyFileImports(imports),
                            script,
                            "</head><body><main></main></body></html>"
                        )
                    )
                )
            );
    }

    function generateManyFileImports(
        FileType[] calldata scripts
    ) public view returns (string memory) {
        string memory imports = "";

        for (uint256 i = 0; i < scripts.length; i++) {
            imports = string.concat(imports, generateFileImport(scripts[i]));
        }

        return imports;
    }

    function generateFileImport(
        FileType calldata script
    ) public view returns (string memory) {
        if (script.fileType == FILE_TYPE_JAVASCRIPT_PLAINTEXT) {
            return
                string.concat(
                    "<script>",
                    IFileSystemAdapter(script.fileSystem).getFile(script.name),
                    "</script>"
                );
        } else if (script.fileType == FILE_TYPE_JAVASCRIPT_BASE64) {
            return
                string.concat(
                    '<script src="data:text/javascript;base64,',
                    IFileSystemAdapter(script.fileSystem).getFile(script.name),
                    '"></script>'
                );
        } else if (script.fileType == FILE_TYPE_JAVASCRIPT_GZIP) {
            return
                string.concat(
                    '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
                    IFileSystemAdapter(script.fileSystem).getFile(script.name),
                    '"></script>'
                );
        }

        revert("Invalid file type");
    }

    function _authorizeUpgrade(address newImpl) internal override onlyOwner {
        if (
            !ITokenFactory(factory).isValidUpgrade(
                _getImplementation(),
                newImpl
            )
        ) {
            revert ITokenFactory.InvalidUpgrade(newImpl);
        }
    }
}
