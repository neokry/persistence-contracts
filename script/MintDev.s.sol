// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MathBlocksFactory.sol";
import "../src/MathBlocksToken.sol";
import "forge-std/console2.sol";

contract Mint is Script {
    function run() public {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address factory = 0xc3023a2c9f7B92d1dd19F488AF6Ee107a78Df9DB;

        vm.startBroadcast(deployerPrivateKey);

        address clone = MathBlocksFactory(factory).create(
            "Test",
            "TST",
            "Test Description",
            'let points=[],inc=0,xOffset=0,squigCount=0,hue=0,pointSpeed=[];const maxPoints=6e3,maxSpeed=5;function setup(){"undefined"!=typeof seed&&(randomSeed(seed),noiseSeed(seed)),createCanvas(window.innerWidth,window.innerHeight),xOffset=random(1,10),squigCount=random(10,40),hue=random(0,255),pointSpeed=[random(-5,5),random(-5,5),]}function draw(){inc+=.005,colorMode(HSB),background(hue+20,100,255);for(let n=0;n<squigCount;n++)generatePoint(n);points.length>6e3&&(points=points.slice(points.length-6e3,points.length)),renderPoints(),corrupt()}function generatePoint(n){let t=10*n;return points.push([noise(inc+t)*width,noise(inc+t*xOffset)*height,5*noise(inc),10*noise(inc*xOffset),[hue,(squigCount-n)*(255/squigCount),n*(255/squigCount),],])}function renderPoints(){for(let n=0;n<points.length;n++){push();let[t,e,i,o,$]=points[n];translate(t,e),noStroke(),fill([...$]),ellipse(0,0,i,o),pop()}}function corrupt(){for(let n=0;n<points.length;n++){let[t,e,i,o,$]=points[n],[s,u]=pointSpeed;points[n]=[noise(inc)*s+t,noise(inc)*u+e,noise(10*inc)+i,noise(10*inc)+o,$,]}}',
            0,
            9999999999999
        );

        MathBlocksToken(clone).safeMint(
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );

        console2.log("html:");
        console2.log(MathBlocksToken(clone).tokenURI(0));

        vm.stopBroadcast();
    }
}
