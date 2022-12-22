// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {IFixedPriceToken} from "../src/tokens/interfaces/IFixedPriceToken.sol";
import {IHTMLRenderer} from "../src/renderer/interfaces/IHTMLRenderer.sol";
import {HTMLRendererStorageV1} from "../src/renderer/storage/HTMLRendererStorageV1.sol";
import "forge-std/console2.sol";

contract Mint is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address owner = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
        address factory = 0x0567758833057088e7f0DB522376343b54Bd17FA;
        address tokenImpl = 0x1e86E360eFc99bEfbD3e795bd0e02e1Be1dfA8FF;
        address htmlRenderer = 0x0859739B7c28b29e45017a69501a94E9E7671F18;
        address ethFSAdapter = 0x426bf59BCc66652960Fd43cE461D5c876D66FE6a;

        vm.startBroadcast(deployerPrivateKey);

        string
            memory script = 'let points=[],inc=0,xOffset=0,squigCount=0,hue=0,pointSpeed=[];const maxPoints=6e3,maxSpeed=5;function setup(){"undefined"!=typeof seed&&(randomSeed(seed),noiseSeed(seed)),createCanvas(window.innerWidth,window.innerHeight),xOffset=random(1,10),squigCount=random(10,40),hue=random(0,255),pointSpeed=[random(-5,5),random(-5,5),]}function draw(){inc+=.005,colorMode(HSB),background(hue+20,100,255);for(let n=0;n<squigCount;n++)generatePoint(n);points.length>6e3&&(points=points.slice(points.length-6e3,points.length)),renderPoints(),corrupt()}function generatePoint(n){let t=10*n;return points.push([noise(inc+t)*width,noise(inc+t*xOffset)*height,5*noise(inc),10*noise(inc*xOffset),[hue,(squigCount-n)*(255/squigCount),n*(255/squigCount),],])}function renderPoints(){for(let n=0;n<points.length;n++){push();let[t,e,i,o,$]=points[n];translate(t,e),noStroke(),fill([...$]),ellipse(0,0,i,o),pop()}}function corrupt(){for(let n=0;n<points.length;n++){let[t,e,i,o,$]=points[n],[s,u]=pointSpeed;points[n]=[noise(inc)*s+t,noise(inc)*u+e,noise(10*inc)+i,noise(10*inc)+o,$,]}}';

        IToken.TokenInfo memory tokenInfo = IToken.TokenInfo({
            name: "Test",
            symbol: "TST",
            description: "Test Description",
            fundsRecipent: owner,
            totalSupply: 99999
        });

        IFixedPriceToken.SaleInfo memory saleInfo = IFixedPriceToken.SaleInfo({
            price: 0,
            startTime: 0,
            endTime: 0
        });

        IHTMLRenderer.FileType[] memory imports = new IHTMLRenderer.FileType[](
            1
        );

        imports[0] = IHTMLRenderer.FileType({
            name: "p5-mc.js",
            fileSystem: ethFSAdapter,
            fileType: 1 //FILE_TYPE_JAVASCRIPT_BASE64
        });

        /*
        imports[1] = IHTMLRenderer.FileType({
            name: "gunzipScripts-0.0.1.js",
            fileSystem: ethFSAdapter,
            fileType: 1 //FILE_TYPE_JAVASCRIPT_BASE64
        });
        */

        bytes memory params = abi.encode(
            script,
            htmlRenderer,
            tokenInfo,
            saleInfo,
            imports
        );

        address clone = TokenFactory(factory).create(tokenImpl, params);

        IToken(clone).safeMint(owner);

        console2.log("clone:");
        console2.log(clone);

        vm.stopBroadcast();
    }
}
