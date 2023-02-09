// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {HTMLRenderer} from "../src/renderer/HTMLRenderer.sol";
import {HTMLRendererProxy} from "../src/renderer/HTMLRendererProxy.sol";
import {IHTMLRenderer} from "../src/renderer/interfaces/IHTMLRenderer.sol";
import {Base64URIDecoder} from "./utils/Base64URIDecoder.sol";
import {TokenFactory} from "../src/TokenFactory.sol";

contract HTMLRendererTest is Test {
    address factory;
    address owner = address(1);
    address notOwner = address(2);
    address upgradeImpl;

    HTMLRenderer renderer;

    /*

    function setUp() public {
        TokenFactory factoryContract = new TokenFactory();
        factory = address(factoryContract);

        address rendererImpl = address(new HTMLRenderer(factory));
        upgradeImpl = address(new HTMLRenderer(factory));

        factoryContract.registerUpgrade(rendererImpl, upgradeImpl);

        renderer = HTMLRenderer(
            address(new HTMLRendererProxy(rendererImpl, ""))
        );
        renderer.initilize(owner);
    }

    function test_upgrade() public {
        vm.prank(owner);
        renderer.upgradeTo(upgradeImpl);
    }

    function testRevert_upgradeNotValid() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSignature("InvalidUpgrade(address)", address(this))
        );
        renderer.upgradeTo(address(this));
    }

    function testRevert_upgradeNotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        renderer.upgradeTo(upgradeImpl);
    }

    function test_generateURI() public view {
        IHTMLRenderer.ExternalScript[]
            memory imports = new IHTMLRenderer.ExternalScript[](3);
        imports[0] = IHTMLRenderer.ExternalScript({
            name: "test",
            scriptType: 0
        });
        imports[1] = IHTMLRenderer.ExternalScript({
            name: "test1",
            scriptType: 1
        });
        imports[2] = IHTMLRenderer.ExternalScript({
            name: "test2",
            scriptType: 2
        });

        string memory uri = renderer.generateURI(imports, "test script");

        string memory decodedURI = Base64URIDecoder.decodeURI(
            "data:text/html;base64,",
            uri
        );

        string memory expectedURI = string.concat(
            '<html><head><style type="text/css">html{height:100%}body{min-height:100%;margin:0;padding:0}canvas{padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0}</style>',
            "<script>",
            "test",
            "</script>",
            '<script src="data:text/javascript;base64,',
            "test1",
            '"></script>',
            '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
            "test2",
            '"></script>'
            "test script",
            "</head><body><main></main></body></html>"
        );

        require(
            keccak256(abi.encodePacked(decodedURI)) ==
                keccak256(abi.encodePacked(expectedURI)),
            "Invalid URI"
        );
    }

    function test_generateManyFileImports() public view {
        IHTMLRenderer.ExternalScript[]
            memory imports = new IHTMLRenderer.ExternalScript[](3);
        imports[0] = IHTMLRenderer.ExternalScript({
            name: "test",
            scriptType: 0
        });

        imports[1] = IHTMLRenderer.ExternalScript({
            name: "test1",
            scriptType: 1
        });

        imports[2] = IHTMLRenderer.ExternalScript({
            name: "test2",
            scriptType: 2
        });

        string memory importString = renderer.generateManyFileImports(imports);

        string memory expected = string.concat(
            "<script>",
            "test",
            "</script>",
            '<script src="data:text/javascript;base64,',
            "test1",
            '"></script>',
            '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
            "test2",
            '"></script>'
        );

        require(
            keccak256(abi.encodePacked(importString)) ==
                keccak256(abi.encodePacked(expected)),
            "Invalid import"
        );
    }

    function test_generateFileImports() public view {
        string memory importString = renderer.generateFileImport(
            IHTMLRenderer.ExternalScript({name: "test", scriptType: 0})
        );

        string memory expected = string.concat("<script>", "test", "</script>");

        require(
            keccak256(abi.encodePacked(importString)) ==
                keccak256(abi.encodePacked(expected)),
            "Invalid import"
        );

        string memory importString1 = renderer.generateFileImport(
            IHTMLRenderer.ExternalScript({name: "test", scriptType: 1})
        );

        string memory expected1 = string.concat(
            '<script src="data:text/javascript;base64,',
            "test",
            '"></script>'
        );

        require(
            keccak256(abi.encodePacked(importString1)) ==
                keccak256(abi.encodePacked(expected1)),
            "Invalid import1"
        );

        string memory importString2 = renderer.generateFileImport(
            IHTMLRenderer.ExternalScript({name: "test", scriptType: 2})
        );

        string memory expected2 = string.concat(
            '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
            "test",
            '"></script>'
        );

        require(
            keccak256(abi.encodePacked(importString2)) ==
                keccak256(abi.encodePacked(expected2)),
            "Invalid import2"
        );
    }
    */
}
