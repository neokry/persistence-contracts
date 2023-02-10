// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Base64} from "base64-sol/base64.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {IFileStore} from "ethfs/IFileStore.sol";
import {File} from "ethfs/File.sol";
import {LibStorage, TokenStorage} from "./LibStorage.sol";

library LibHTMLRenderer {
    error InvalidScriptType();

    enum ScriptType {
        JAVASCRIPT_PLAINTEXT,
        JAVASCRIPT_BASE64,
        JAVASCRIPT_GZIP,
        CUSTOM
    }

    struct ScriptRequest {
        ScriptType scriptType;
        string name;
        bytes data;
        bytes urlEncodedPrefix;
        bytes urlEncodedSuffix;
    }

    //<html><head><style type="text/css">html{height:100%}body{min-height:100%;margin:0;padding:0}canvas{padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0}</style>
    bytes constant HTML_START =
        "%253Chtml%253E%253Chead%253E%253Cstyle%2520type=%2522text/css%2522%253Ehtml%257Bheight:100%2525%257Dbody%257Bmin-height:100%2525;margin:0;padding:0%257Dcanvas%257Bpadding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0%257D%253C/style%253E";

    //</head><body><main></main></body></html>
    bytes constant HTML_END =
        "%253C/head%253E%253Cbody%253E%253Cmain%253E%253C/main%253E%253C/body%253E%253C/html%253E";

    //<script src="data:text/javascript;base64,
    bytes constant SCRIPT_OPEN_BASE64 =
        "%253Cscript%2520src=%2522data:text/javascript;base64,";

    //<script type="text/javascript+gzip" src="data:text/javascript;base64,
    bytes constant SCRIPT_OPEN_GZIP =
        "%253Cscript%2520type=%2522text/javascript+gzip%2522%2520src=%2522data:text/javascript;base64,";

    //"></script>
    bytes constant SCRIPT_CLOSE_WITH_END_TAG = "%2522%253E%253C/script%253E";

    uint256 constant HTML_TOTAL_BYTES = 355;

    uint256 constant SCRIPT_BASE64_BYTES = 80;

    uint256 constant SCRIPT_GZIP_BYTES = 120;

    function ts() internal pure returns (TokenStorage storage) {
        return LibStorage.tokenStorage();
    }

    // [[[ View Functions ]]]

    function getTotalHTMLSize(
        ScriptRequest[] calldata scripts
    ) external view returns (uint256) {
        uint256 length = scripts.length;
        uint256 i = 0;
        uint256 scriptBytes = 0;
        do {
            scriptBytes =
                getScriptData(scripts[i]).length +
                getScriptSize(scripts[i]);
        } while (++i < length);
        return HTML_TOTAL_BYTES + scriptBytes;
    }

    function getScriptSize(
        ScriptRequest calldata script
    ) public pure returns (uint256) {
        if (
            script.urlEncodedPrefix.length > 0 &&
            script.urlEncodedSuffix.length > 0
        )
            return
                script.urlEncodedPrefix.length + script.urlEncodedSuffix.length;
        else if (script.scriptType <= ScriptType.JAVASCRIPT_BASE64)
            return SCRIPT_BASE64_BYTES;
        else if (script.scriptType == ScriptType.JAVASCRIPT_GZIP)
            return SCRIPT_GZIP_BYTES;
        else revert InvalidScriptType();
    }

    // [[[ HTML Generation Functions ]]]

    /**
     * @notice Construct url safe html from the given scripts.
     */
    function generateURLSafeHTML(
        ScriptRequest[] calldata scripts,
        uint256 bufferSize
    ) external view returns (bytes memory) {
        bytes memory buffer = DynamicBuffer.allocate(bufferSize);

        DynamicBuffer.appendSafe(buffer, HTML_START);
        appendScripts(buffer, scripts);
        DynamicBuffer.appendSafe(buffer, HTML_END);

        return buffer;
    }

    function appendScripts(
        bytes memory buffer,
        ScriptRequest[] calldata scripts
    ) internal view {
        bytes memory prefix;
        bytes memory suffix;
        uint256 i;
        uint256 length = scripts.length;

        unchecked {
            do {
                (prefix, suffix) = getScriptPrefixAndSuffix(scripts[i]);
                DynamicBuffer.appendSafe(buffer, prefix);
                if (scripts[i].scriptType == ScriptType.JAVASCRIPT_PLAINTEXT)
                    DynamicBuffer.appendSafeBase64(
                        buffer,
                        getScriptData(scripts[i]),
                        false,
                        false
                    );
                else
                    DynamicBuffer.appendSafe(buffer, getScriptData(scripts[i]));
                DynamicBuffer.appendSafe(buffer, suffix);
            } while (++i < length);
        }
    }

    function getScriptData(
        ScriptRequest calldata script
    ) internal view returns (bytes memory) {
        return
            script.data.length > 0
                ? script.data
                : bytes(IFileStore(ts().ethFS).getFile(script.name).read());
    }

    function getScriptPrefixAndSuffix(
        ScriptRequest calldata script
    ) internal pure returns (bytes memory, bytes memory) {
        if (
            script.urlEncodedPrefix.length > 0 &&
            script.urlEncodedSuffix.length > 0
        ) return (script.urlEncodedPrefix, script.urlEncodedSuffix);
        else if (script.scriptType <= ScriptType.JAVASCRIPT_BASE64)
            return (SCRIPT_OPEN_BASE64, SCRIPT_CLOSE_WITH_END_TAG);
        else if (script.scriptType == ScriptType.JAVASCRIPT_GZIP)
            return (SCRIPT_OPEN_GZIP, SCRIPT_CLOSE_WITH_END_TAG);
        else revert InvalidScriptType();
    }
}
