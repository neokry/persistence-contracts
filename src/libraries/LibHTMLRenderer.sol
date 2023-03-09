// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {IFileStore} from "ethfs/IFileStore.sol";
import {File} from "ethfs/File.sol";

library LibHTMLRenderer {
    error InvalidScriptType();

    enum ScriptType {
        JAVASCRIPT_PLAINTEXT,
        JAVASCRIPT_BASE64,
        JAVASCRIPT_URL_ENCODED,
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

    // [[[ Single url encoded tags ]]]

    //data:text/html,
    bytes public constant HTML_TAG_URL_SAFE = "data%3Atext%2Fhtml%2C";

    // [[[ Double url encoded tags ]]]

    //<body><style type="text/css">html{height:100%}body{min-height:100%;margin:0;padding:0}canvas{padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0}</style>
    bytes constant HTML_START =
        "%253Cbody%253E%253Cstyle%2520type=%2522text/css%2522%253Ehtml%257Bheight:100%2525%257Dbody%257Bmin-height:100%2525;margin:0;padding:0%257Dcanvas%257Bpadding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0%257D%253C/style%253E";

    //</body>
    bytes constant HTML_END = "%253C/body%253E";

    //<script>
    bytes constant SCRIPT_OPEN_PLAINTEXT = "%253Cscript%253E";

    //<script src="data:text/javascript;base64,
    bytes constant SCRIPT_OPEN_BASE64 =
        "%253Cscript%2520src=%2522data:text/javascript;base64,";

    //<script type="text/javascript+gzip" src="data:text/javascript;base64,
    bytes constant SCRIPT_OPEN_GZIP =
        "%253Cscript%2520type=%2522text/javascript+gzip%2522%2520src=%2522data:text/javascript;base64,";

    //</script>
    bytes constant SCRIPT_CLOSE_PLAINTEXT = "%253C/script%253E";

    //"></script>
    bytes constant SCRIPT_CLOSE_WITH_END_TAG = "%2522%253E%253C/script%253E";

    uint256 constant HTML_TOTAL_BYTES = 376;

    uint256 constant SCRIPT_BASE64_BYTES = 80;

    uint256 constant SCRIPT_GZIP_BYTES = 120;

    uint256 constant SCRIPT_PLAINTEXT_BYTES = 33;

    // [[[ HTML Generation Functions ]]]

    /**
     * @notice Construct url safe html from the given scripts.
     */
    function generateDoubleURLEncodedHTML(
        ScriptRequest[] calldata scripts,
        address ethFS
    ) external view returns (bytes memory) {
        uint256 i = 0;
        uint256 length = scripts.length;
        bytes[] memory scriptData = new bytes[](length);
        uint256 bufferSize = HTML_TOTAL_BYTES;

        unchecked {
            do {
                scriptData[i] = getScriptData(scripts[i], ethFS);
                bufferSize +=
                    (
                        scripts[i].scriptType == ScriptType.JAVASCRIPT_PLAINTEXT
                            ? sizeForBase64Encoding(scriptData[i].length)
                            : scriptData[i].length
                    ) +
                    getScriptSize(scripts[i]);
            } while (++i < length);
        }

        bytes memory buffer = DynamicBuffer.allocate(bufferSize);

        DynamicBuffer.appendSafe(buffer, HTML_TAG_URL_SAFE);
        DynamicBuffer.appendSafe(buffer, HTML_START);
        appendScripts(buffer, scripts, scriptData, ethFS);
        DynamicBuffer.appendSafe(buffer, HTML_END);

        return buffer;
    }

    function appendScripts(
        bytes memory buffer,
        ScriptRequest[] calldata scripts,
        bytes[] memory scriptData,
        address ethfs
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
                        scriptData[i],
                        false,
                        false
                    );
                else
                    DynamicBuffer.appendSafe(
                        buffer,
                        getScriptData(scripts[i], ethfs)
                    );
                DynamicBuffer.appendSafe(buffer, suffix);
            } while (++i < length);
        }
    }

    function getScriptData(
        ScriptRequest calldata script,
        address ethFS
    ) internal view returns (bytes memory) {
        return
            script.data.length > 0
                ? script.data
                : bytes(IFileStore(ethFS).getFile(script.name).read());
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
        else if (script.scriptType == ScriptType.JAVASCRIPT_URL_ENCODED)
            return SCRIPT_PLAINTEXT_BYTES;
        else if (script.scriptType == ScriptType.JAVASCRIPT_GZIP)
            return SCRIPT_GZIP_BYTES;
        else revert InvalidScriptType();
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
        else if (script.scriptType == ScriptType.JAVASCRIPT_URL_ENCODED)
            return (SCRIPT_OPEN_PLAINTEXT, SCRIPT_CLOSE_PLAINTEXT);
        else if (script.scriptType == ScriptType.JAVASCRIPT_GZIP)
            return (SCRIPT_OPEN_GZIP, SCRIPT_CLOSE_WITH_END_TAG);
        else revert InvalidScriptType();
    }

    function sizeForBase64Encoding(
        uint256 value
    ) internal pure returns (uint256) {
        unchecked {
            return 4 * ((value + 2) / 3);
        }
    }
}
