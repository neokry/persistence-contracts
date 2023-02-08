// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Base64} from "base64-sol/base64.sol";
import {IFileSystemAdapter} from "../fileSystemAdapters/interfaces/IFileSystemAdapter.sol";
import {IHTMLRenderer} from "./interfaces/IHTMLRenderer.sol";
import {HTMLRendererStorageV1} from "./storage/HTMLRendererStorageV1.sol";
import {UUPS} from "../vendor/proxy/UUPS.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {VersionedContract} from "../VersionedContract.sol";
import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {IFileStore} from "ethfs/IFileStore.sol";
import {File} from "ethfs/File.sol";

contract HTMLRenderer is
    IHTMLRenderer,
    HTMLRendererStorageV1,
    UUPS,
    Ownable2StepUpgradeable,
    VersionedContract
{
    address immutable factory;
    IFileStore immutable ethfs;

    string constant DATA_HEADER = "data:text/html;base64,";
    bytes constant HTML_START =
        bytes(
            '<html><head><style type="text/css">html{height:100%}body{min-height:100%;margin:0;padding:0}canvas{padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0}</style>'
        );
    bytes constant HTML_END = bytes("</head><body><main></main></body></html>");
    bytes constant SCRIPT_OPEN_PLAINTEXT = bytes("<script>");
    bytes constant SCRIPT_OPEN_BASE64 =
        bytes('<script src="data:text/javascript;base64,');
    bytes constant SCRIPT_OPEN_GZIP =
        bytes(
            '<script type="text/javascript+gzip" src="data:text/javascript;base64,'
        );
    bytes constant SCRIPT_CLOSE = bytes("</script>");
    bytes constant SCRIPT_CLOSE_WITH_END_TAG = bytes('"></script>');

    constructor(address _factory, IFileStore _ethfs) {
        factory = _factory;
        ethfs = _ethfs;
    }

    /// @notice set the owner of the contract
    function initilize(address owner) external initializer {
        _transferOwnership(owner);
    }

    /**
     * @notice Construct an html URI from the given script and imports.
     */
    function generateURI(
        FileType[] calldata imports,
        bytes calldata script
    ) public view returns (string memory) {
        (File[] memory files, uint256 totalSize) = _getAllFilesAndTotalSize(
            imports
        );

        bytes memory buffer = DynamicBuffer.allocate(
            totalSize + script.length + 100
        );

        // Generate the HTML / javascript
        DynamicBuffer.appendUnchecked(buffer, HTML_START);
        generateManyFileImports(buffer, imports, files);
        DynamicBuffer.appendUnchecked(buffer, script);
        DynamicBuffer.appendUnchecked(buffer, HTML_END);

        // base64 encode the buffer and prepend the data header
        return string.concat(DATA_HEADER, Base64.encode(buffer));
    }

    /// @notice Returns the HTML for the given imports
    function generateManyFileImports(
        bytes memory buffer,
        FileType[] calldata _imports,
        File[] memory _files
    ) public view {
        for (uint256 i = 0; i < _imports.length; ++i) {
            generateFileImport(buffer, _imports[i], _files[i]);
        }
    }

    /// @notice Returns the HTML for a single import
    function generateFileImport(
        bytes memory buffer,
        FileType calldata script,
        File memory file
    ) public view {
        // Script open tag
        if (script.fileType == FILE_TYPE_JAVASCRIPT_PLAINTEXT)
            DynamicBuffer.appendUnchecked(buffer, SCRIPT_OPEN_PLAINTEXT);
        else if (script.fileType == FILE_TYPE_JAVASCRIPT_BASE64)
            DynamicBuffer.appendUnchecked(buffer, SCRIPT_OPEN_BASE64);
        else if (script.fileType == FILE_TYPE_JAVASCRIPT_GZIP)
            DynamicBuffer.appendUnchecked(buffer, SCRIPT_OPEN_GZIP);

        // File content
        DynamicBuffer.appendUnchecked(buffer, bytes(file.read()));

        // Script close tag
        if (script.fileType == FILE_TYPE_JAVASCRIPT_PLAINTEXT)
            DynamicBuffer.appendUnchecked(buffer, SCRIPT_CLOSE);
        else if (
            script.fileType == FILE_TYPE_JAVASCRIPT_BASE64 ||
            script.fileType == FILE_TYPE_JAVASCRIPT_GZIP
        ) DynamicBuffer.appendUnchecked(buffer, SCRIPT_CLOSE_WITH_END_TAG);
    }

    function _getAllFilesAndTotalSize(
        FileType[] calldata imports
    ) private view returns (File[] memory, uint256) {
        uint256 len = imports.length;
        uint256 totalSize = 0;
        File[] memory files = new File[](len);

        for (uint256 i = 0; i < len; ++i) {
            File memory curr = ethfs.getFile(imports[i].name);
            files[i] = curr;
            totalSize += curr.size;
        }
        return (files, totalSize);
    }

    /// @notice check if the upgrade is valid
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
