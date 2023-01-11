// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TokenFactory} from "../src/TokenFactory.sol";
import {IToken} from "../src/tokens/interfaces/IToken.sol";
import {IFixedPriceToken} from "../src/tokens/interfaces/IFixedPriceToken.sol";
import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";
import {IHTMLRenderer} from "../src/renderer/interfaces/IHTMLRenderer.sol";
import {HTMLRendererStorageV1} from "../src/renderer/storage/HTMLRendererStorageV1.sol";
import "forge-std/console2.sol";

contract Mint is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEV");

        address owner = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
        address factory = 0xFCFE742e19790Dd67a627875ef8b45F17DB1DaC6;
        address tokenImpl = 0xbe18A1B61ceaF59aEB6A9bC81AB4FB87D56Ba167;
        address htmlRenderer = 0x398E4948e373Db819606A459456176D31C3B1F91;
        address ethFSAdapter = 0x25C0a2F0A077F537Bd11897F04946794c2f6f1Ef;

        vm.startBroadcast(deployerPrivateKey);

        string
            memory script = 'let planets=[],xoff=0;function setup(){colorMode(HSB),createCanvas(400,400),angleMode(DEGREES);planets=[new Planet(60,200,300,120,1,80),new Planet(80,200,200,200,2,70),new Planet(20,200,180,140,4,300),new Planet(10,200,200,140,3,210),new Planet(26,200,140,240,1,111),new Planet(200,200,200,0,1,220),]}function draw(){background(0),createGrid(),planets.map($=>$.draw())}function createGrid(){let $=3*noise(xoff+=.01);for(let t=0;t<360;t+=$){let i=width/2+width*cos(t),s=height/2+width*sin(t);stroke(100,100,100),line(width/2,height/2,i,s)}}class Planet{constructor($,t,i,s,a,e){this.radius=$,this.x=t,this.y=i,this.scalar=s,this.angle=0,this.speed=a,this.color=e}draw(){let $=this.x-this.radius,t=this.y-this.radius,i=this.x+this.radius,s=this.y+this.radius,a=drawingContext.createRadialGradient($,t,i,s,200,20),e=color(100,100,100),l=color(100,100,100);a.addColorStop(0,e.toString()),a.addColorStop(.5,l.toString()),a.addColorStop(1,e.toString()),drawingContext.fillStyle=a,noStroke();let n=this.x+this.scalar*cos(this.angle),r=this.y+this.scalar*sin(this.angle);ellipse(n,r,this.radius,this.radius),drawingContext.fillStyle="white",this.angle+=this.speed}}';
        string
            memory previewBaseURI = "https://math-blocks.vercel.app/api/preview/";

        IToken.TokenInfo memory tokenInfo = IToken.TokenInfo({
            name: "Test",
            symbol: "TST",
            description: "Test Description",
            fundsRecipent: owner,
            maxSupply: 99999
        });

        IFixedPriceToken.SaleInfo memory saleInfo = IFixedPriceToken.SaleInfo({
            artistProofCount: 1,
            price: 0,
            startTime: 0,
            endTime: 0
        });

        IHTMLRenderer.FileType[] memory imports = new IHTMLRenderer.FileType[](
            2
        );

        imports[0] = IHTMLRenderer.FileType({
            name: "p5-v1.5.0.min.js.gz",
            fileSystem: ethFSAdapter,
            fileType: 2 //FILE_TYPE_JAVASCRIPT_GZIP
        });

        imports[1] = IHTMLRenderer.FileType({
            name: "gunzipScripts-0.0.1.js",
            fileSystem: ethFSAdapter,
            fileType: 1 //FILE_TYPE_JAVASCRIPT_BASE64
        });

        bytes memory params = abi.encode(
            script,
            previewBaseURI,
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
