// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IHTMLRenderer} from "../src/renderer/interfaces/IHTMLRenderer.sol";

import {FixedPriceToken} from "../src/tokens/FixedPriceToken.sol";

contract Upgrade is Script {
    using Strings for uint256;

    string configFile;
    address constant TOKEN_TO_UPGRADE =
        0xb1bB11D6b0945A07e7a313050683B910cE0AF8fF;
    string constant SCRIPT_UPGRADE =
        'let cyano=[44,46,75],creamSpore=[173,161,128],clay=[143,106,116],cOrall=[152,87,87],west=[173,161,128],rust=[185,71,30],blackRust=[18,2,2],darkRed=[147,30,18],kuramaOrange=[234,97,42],kuramaDark=[26,37,39],kuramaCloak=[245,245,14],rasengan=[134,223,252],nightGardenGreen=[117,251,76],nigthGardenPink=[232,57,183],maroooon=[154,31,110],poisonMoss=[61,126,34],glitchPalmBlue=[44,98,209],glitchPalmOrange=[193,94,48],brick=[124,28,23],wetMold=[35,84,117],pastelRollerCoasterYellow=[226,216,133],pastelRollerCoasterBlue=[142,208,224],pastelSand=[224,188,129],pastelDust=[180,111,50],ube=[183,185,239],car=[213,111,49],blu=[112,147,247],bluberi=[78,63,158],sgSkin=[162,210,169],sgNip=[191,179,129],sg3=[149,142,125],sg4=[159,161,94],colorPalettes=[[cyano,creamSpore,clay,cOrall],[kuramaOrange,kuramaDark,rasengan,kuramaCloak],[west,rust,blackRust,darkRed],[nightGardenGreen,nigthGardenPink,maroooon,poisonMoss],[glitchPalmBlue,glitchPalmOrange,brick,wetMold],[pastelRollerCoasterYellow,pastelRollerCoasterBlue,pastelSand,pastelDust],[ube,car,blu,bluberi],[sgSkin,sgNip,sg3,sg4],],colorPalette,backgroundColor,circleColor,currentBeatColor=[189,43,60],buttonOnColor,accentColor,initialMouse=!1,now,tempo,millisPerBeat,lastBeat=0,beat=0,subdivision=0,beatsPerMeasure,sounds=[],delay=new p5.Delay,bassDelay=new p5.Delay,harmonicRatios=[1,1.0593878,1.122449,1.189184,1.26,1.33489796,1.41428571,1.498367,1.58735,1.681837,1.78184,1.887755,2,],bassHarmonics=[.5,.5298,.56122,.5947,.63,.6673,.70714,.74918,.7937,.8408,.8622,.9439,1,],subdivisions,keyFreqRatio,beatButtons,sliders,playing=!1,currentSoundIndex=0,rt={};function setup(){document.body.style.TouchAction="none",getAudioContext().suspend(),"undefined"!=typeof tokenId?(console.log("token id: ",tokenId),randomSeed(tokenId+3098)):randomSeed(3098),createCanvas(windowWidth,windowHeight),chooseColors(),angleMode(DEGREES),millisPerBeat=60/(tempo=300)*1e3,subdivisions=floor(random(6,40)),console.log("subs: "+subdivisions),beatButtons=new beatButtonInterface(subdivisions,!0),keyFreqRatio=random(bassHarmonics),console.log("keyFreqRatio: "+keyFreqRatio),sounds[0]=new sound("bass_drum"),sounds[1]=new sound("hi_hat"),sounds[2]=new sound("synth01"),sounds[3]=new sound("synth02"),rt=window.rt,playing||(playing=!0)}function draw(){mouseIsPressed&&(beatButtons.display(),sliders.display()),initialMouse&&sliders.animate(),beatButtons.play&&playAudio()}function playAudio(){if((now=millis())-lastBeat>=millisPerBeat){beatButtons.next();for(let t=0;t<beatButtons.rows[beat].length;t++)beatButtons.rows[beat][t].on&&sounds[t].play();lastBeat=now}}const loadInitalData=async()=>{await rt?.init();let{data:t}=rt?.getToken({tokenId});t&&loadPattern(t)};function chooseColors(){colorPalette=random(colorPalettes),.5>=random()?(backgroundColor=colorPalette[0],circleColor=colorPalette[1]):(backgroundColor=colorPalette[1],circleColor=colorPalette[0]),buttonOnColor=colorPalette[2],accentColor=colorPalette[3],background(backgroundColor[0],backgroundColor[1],backgroundColor[2])}class beatButtonInterface{constructor(t,s){noStroke(),this.subdivisions=t,this.yStart=.1*windowHeight,this.yGap=.25;let e=.84*windowHeight;this.diameter=e/(t*(1+this.yGap)-this.yGap),this.xGap=.3*this.diameter,this.xStart=this.diameter/2+windowWidth/2-2*this.diameter-1.5*this.xGap,s||(this.xStart=this.xStart-.25*windowWidth),this.xGap=.3*this.diameter,this.rows=[],fill(circleColor[0],circleColor[1],circleColor[2]),this.xStop=0;for(let i=0;i<subdivisions;i++){let o=[];for(let r=0;r<4;r++)o[r]=new beatButton(this.xStart+r*(this.diameter+this.xGap),this.yStart+i*(this.diameter+this.diameter*this.yGap),this.diameter),i==subdivisions-1&&3==r&&(this.xStop=this.diameter/2+this.xStart+r*(this.diameter+this.xGap));this.rows[i]=o}}next(){this.play&&(this.turnRowOff(beat),beat=(beat+1)%subdivisions,this.turnRowOn(beat))}start(){this.play=!0,lastBeat=millis(),beat=0,this.turnRowOn(0)}reset(){if(lastBeat=millis(),this.turnRowOff(beat),beat=0,this.turnRowOn(0),this.play)for(let t=0;t<beatButtons.rows[beat].length;t++)beatButtons.rows[beat][t].on&&sounds[t].play()}pause(){this.play=!this.play}turnRowOn(t){this.rows[t][0].turnOn(),this.rows[t][1].turnOn(),this.rows[t][2].turnOn(),this.rows[t][3].turnOn()}turnRowOff(t){this.rows[t][0].turnOff(),this.rows[t][1].turnOff(),this.rows[t][2].turnOff(),this.rows[t][3].turnOff()}display(){for(let t=0;t<this.rows.length;t++)for(let s=0;s<this.rows[t].length;s++)this.rows[t][s].collision()&&(this.rows[t][s].toggle(),currentSoundIndex=s)}}class beatButton{constructor(t,s,e){this.x=t,this.y=s,this.diameter=e,this.on=!1,this.play=!1,circle(this.x,this.y,e)}collision(){let t=this.x-mouseX,s=this.y-mouseY;return pow(pow(t,2)+pow(s,2),.5)<=this.diameter/2}toggle(){if(millis()-this.lastPush<20){this.lastPush=millis();return}this.lastPush=millis(),this.on=!this.on,this.on?(fill(buttonOnColor[0],buttonOnColor[1],buttonOnColor[2]),circle(this.x,this.y,this.diameter)):(fill(circleColor[0],circleColor[1],circleColor[2]),circle(this.x,this.y,this.diameter))}turnOn(){fill(currentBeatColor[0],currentBeatColor[1],currentBeatColor[2]),circle(this.x,this.y,this.diameter)}turnOff(){this.on?fill(buttonOnColor[0],buttonOnColor[1],buttonOnColor[2]):fill(circleColor[0],circleColor[1],circleColor[2]),circle(this.x,this.y,this.diameter)}}class sliderInterface{constructor(t,s,e){this.sliders=[],s+=.1*windowWidth;for(let i=0;i<t;i++)this.sliders[i]=new slider(s,50+e+i*(.15*windowHeight),.4*windowWidth,44,24)}display(){for(let t=0;t<this.sliders.length;t++)this.sliders[t].collision()}animate(){for(let t=0;t<this.sliders.length;t++)this.sliders[t].animate()}}class slider{constructor(t,s,e,i,o){this.x=t,this.y=s,this.length=e,this.height=i,this.curviness=o,this.valueSequence=[];for(let r=0;r<subdivisions;r++){this.valueSequence[r]=[];for(let l=0;l<sounds.length;l++)this.valueSequence[r][l]=.06}fill(accentColor[0],accentColor[1],accentColor[2]),this.topShape=rect(this.x,this.y,e+13,this.height,this.curviness),fill(circleColor[0],circleColor[1],circleColor[2]),this.baseShape=rect(t,s,e,i,o),fill(buttonOnColor[0],buttonOnColor[1],buttonOnColor[2]),this.topShape=rect(t,s,e/8,i,o)}collision(){this.y<=mouseY&&mouseY<=this.y+this.height&&this.x<=mouseX&&mouseX<=this.x+this.length&&(strokeWeight(0),fill(circleColor[0],circleColor[1],circleColor[2]),this.baseShape=rect(this.x,this.y,this.length,this.height,this.curviness),mouseX-this.x<=2*this.curviness?(fill(accentColor[0],accentColor[1],accentColor[2]),this.topShape=rect(this.x,this.y,2.5*this.curviness+13,this.height,this.curviness),fill(buttonOnColor[0],buttonOnColor[1],buttonOnColor[2]),this.topShape=rect(this.x,this.y,2.5*this.curviness,this.height,this.curviness)):(fill(accentColor[0],accentColor[1],accentColor[2]),this.topShape=rect(this.x,this.y,mouseX-this.x+13,this.height,this.curviness),fill(buttonOnColor[0],buttonOnColor[1],buttonOnColor[2]),this.topShape=rect(this.x,this.y,mouseX-this.x,this.height,this.curviness)),this.valueSequence[beat][currentSoundIndex]=(mouseX-this.x)/this.length)}currentValue(t){return t!=currentSoundIndex?this.valueSequence[beat][t]:mouseIsPressed&&this.y<=mouseY&&mouseY<=this.y+this.height&&this.x<=mouseX&&mouseX<=this.x+this.length?(mouseX-this.x)/this.length:this.valueSequence[beat][currentSoundIndex]}animate(){fill(circleColor[0],circleColor[1],circleColor[2]),this.baseShape=rect(this.x,this.y,this.length,this.height,this.curviness);let t=this.valueSequence[beat][currentSoundIndex]*this.length;t<=2*this.curviness?(fill(accentColor[0],accentColor[1],accentColor[2]),this.topShape=rect(this.x,this.y,2.5*this.curviness+13,this.height,this.curviness),fill(buttonOnColor[0],buttonOnColor[1],buttonOnColor[2]),this.topShape=rect(this.x,this.y,2.5*this.curviness,this.height,this.curviness)):(fill(accentColor[0],accentColor[1],accentColor[2]),this.topShape=rect(this.x,this.y,t+13,this.height,this.curviness),fill(buttonOnColor[0],buttonOnColor[1],buttonOnColor[2]),this.topShape=rect(this.x,this.y,t,this.height,this.curviness))}}function mousePressed(){initialMouse||(userStartAudio(),initialMouse=!0,background(backgroundColor[0],backgroundColor[1],backgroundColor[2]),beatButtons=new beatButtonInterface(subdivisions,!1),sliders=new sliderInterface(2,beatButtons.xStop,.63*windowHeight),loadInitalData(),beatButtons.start())}function loadPattern(t){console.log("loading pattern",sliders);for(let s=0;s<t.beatButtons.length;s++){let e=t.beatButtons[s];for(let i=0;i<e.length;i++)1==e[i]&&beatButtons.rows[s][i].toggle()}for(let o=0;o<subdivisions;o++)for(let r=0;r<4;r++)sliders.sliders[0].valueSequence[o][r]=t.sliders[r][0][o],sliders.sliders[1].valueSequence[o][r]=t.sliders[r][1][o];millisPerBeat=60/(tempo=t.tempo)*1e3}function savePattern(){let t={beatButtons:[],sliders:[],tempo:0};for(let s=0;s<beatButtons.rows.length;s++){let e=beatButtons.rows[s];for(let i=0;i<e.length;i++)t.beatButtons[s]||(t.beatButtons[s]=[]),t.beatButtons[s][i]=e[i].on?1:0}for(let o=0;o<subdivisions;o++)for(let r=0;r<4;r++)t.sliders[r]||(t.sliders[r]=[]),t.sliders[r][0]||(t.sliders[r][0]=[]),t.sliders[r][1]||(t.sliders[r][1]=[]),t.sliders[r][0][o]=sliders.sliders[0].valueSequence[o][r],t.sliders[r][1][o]=sliders.sliders[1].valueSequence[o][r];t.tempo=tempo,console.log("tokenId",tokenId),rt.mutateToken({tokenId,data:t}),rt.commitToken({tokenId})}function touchStarted(){mousePressed()}function keyTyped(){"r"===key||"R"===key?beatButtons.reset():32==keyCode?(beatButtons.pause(),!1==beatButtons.play&&savePattern()):189==keyCode?millisPerBeat=60/--tempo*1e3:187==keyCode&&(millisPerBeat=60/++tempo*1e3)}class sound{constructor(t){if(this.envelope=new p5.Envelope,this.bassDrum=!1,this.hiHat=!1,this.synth01=!1,this.synth02=!1,this.instrument=t,this.oscillators=[],this.currentlyPlaying=!1,"bass_drum"==t)this.bassDrum=!0,this.startFrequency=98*keyFreqRatio,this.oscillators[0]=new p5.Oscillator("sine"),this.oscillators[0].amp(this.envelope),this.oscillators[0].freq(this.startFrequency),this.filter=new p5.HighPass,this.filter.freq(120),this.filter.res(16),this.oscillators[0].connect(this.filter),this.setADSR(5e-4,.2,0,.015);else if("hi_hat"==t)this.oscillators[0]=new p5.Noise,this.oscillators[0].amp(this.envelope),this.hiHat=!0,this.setADSR(1e-4,.07,.001,.02);else if("synth01"==t){this.envelope=[],this.envelope[0]=new p5.Envelope,this.envelope[1]=new p5.Envelope,this.synth01=!0,this.oscillators[0]=new p5.SawOsc,this.oscillators[1]=new p5.SqrOsc,this.startFrequency=[],this.filter=[],this.startFrequency[0]=391.995*keyFreqRatio,this.startFrequency[1]=198.2475*keyFreqRatio,this.currentFreq=this.startFrequency[0],this.oscillators[0].amp(this.envelope[0]),this.oscillators[0].freq(this.startFrequency[0]),this.oscillators[1].amp(this.envelope[1]),this.oscillators[1].freq(this.startFrequency[1]),this.filter[0]=new p5.LowPass,this.filter[1]=new p5.LowPass,this.oscillators[0].disconnect(),this.oscillators[1].disconnect(),this.oscillators[0].connect(this.filter[0]),this.oscillators[1].connect(this.filter[1]),this.filter[0].freq(this.startFrequency[0]),this.filter[1].freq(this.startFrequency[1]),this.filter[0].res(10),this.filter[1].res(18);let s=.01,e=.02,i=.2,o=.2;this.setADSR(s,e,i,o),this.oscillators[0].amp(this.envelope[0]),this.oscillators[1].amp(this.envelope[1])}else if("synth02"==t){this.envelope=[],this.envelope[0]=new p5.Envelope,this.envelope[1]=new p5.Envelope,this.synth02=!0,this.oscillators[0]=new p5.SawOsc,this.oscillators[1]=new p5.SqrOsc,this.startFrequency=[],this.filter=[],this.startFrequency[0]=sounds[2].currentFreq,this.startFrequency[1]=3+this.startFrequency[0],this.oscillators[0].amp(this.envelope[0]),this.oscillators[0].freq(this.startFrequency[0]),this.oscillators[1].amp(this.envelope[1]),this.oscillators[1].freq(this.startFrequency[1]),this.filter[0]=new p5.LowPass,this.filter[1]=new p5.LowPass,this.oscillators[0].disconnect(),this.oscillators[1].disconnect(),this.oscillators[0].connect(this.filter[0]),this.oscillators[1].connect(this.filter[1]),this.filter[0].freq(this.startFrequency[0]),this.filter[1].freq(this.startFrequency[1]),this.filter[0].res(10),this.filter[1].res(18);let r=.01,l=.001,n=.25,a=.35;this.setADSR(r,l,n,a),this.oscillators[0].amp(this.envelope[0]),this.oscillators[1].amp(this.envelope[1])}}setADSR(t,s,e,i){this.bassDrum?(this.oscillators[0].start(),this.envelope.setADSR(t,s,e,i),this.envelope.mult(3),bassDelay.process(this.oscillators[0],0,0,1e4)):this.hiHat?(this.oscillators[0].start(),this.envelope.setADSR(t,s,e,i),this.envelope.setRange(.32,0),delay.process(this.oscillators[0],.1,.2,1e4),this.envelope.setExp(),this.envelope.mult(1.4)):this.synth01?(this.oscillators[0].start(),this.oscillators[1].start(),this.envelope[0].setADSR(t,s,e,i),this.envelope[1].setADSR(t+.1,s,e,i+.05)):this.synth02&&(this.oscillators[0].start(),this.oscillators[1].start(),this.envelope[0].setADSR(t,s,e,i),this.envelope[1].setADSR(t+.1,s,e,i+.05))}play(){if(this.bassDrum){let t=map(sliders.sliders[0].currentValue(0)-.06,0,1,0,1.5),s=map(sliders.sliders[1].currentValue(0)-.06,0,1,0,5);if(s<1)bassDelay.process(this.oscillators[0],0,0,1e4);else{let e=millisPerBeat/(s+1)/1e3;bassDelay.process(this.oscillators[0],e,.4+s/30,5e3)}this.oscillators[0].freq(this.startFrequency+this.startFrequency*t-.06),this.envelope.play()}else if(this.hiHat){let i=.05+.8*sliders.sliders[0].currentValue(1),o=.01+.8*sliders.sliders[1].currentValue(1);delay.process(this.oscillators[0],i,o,1e4),this.envelope.play()}else if(this.synth01){let r=map(sliders.sliders[0].currentValue(2)-.06,0,1,0,1.5),l=[];l[0]=this.startFrequency[0]+this.startFrequency[0]*r-.06,l[1]=this.startFrequency[1]+this.startFrequency[1]*r-.06,this.oscillators[0].freq(l[0]),this.oscillators[1].freq(l[1]);let n=l[0]*map(sliders.sliders[1].currentValue(2),0,1,.7,1.5);this.filter[0].freq(n),n=l[1]*map(sliders.sliders[1].currentValue(2),0,1,.7,1.5),this.filter[1].freq(n),this.envelope[0].play(),this.envelope[1].play(),this.currentFreq=l[0]}else if(this.synth02){let a=harmonicRatios[floor(map(sliders.sliders[0].currentValue(3)-.06,0,1,0,13))],h=[];h[0]=sounds[2].currentFreq*a,h[1]=(sounds[2].currentFreq+3)*a,this.oscillators[0].freq(h[0]),this.oscillators[1].freq(h[1]);let $=h[0]*map(sliders.sliders[1].currentValue(3),0,1,.7,1.5);this.filter[0].freq($),$=h[1]*map(sliders.sliders[1].currentValue(3),0,1,.7,1.5),this.filter[1].freq($),this.envelope[0].play(),this.envelope[1].play()}this.currentlyPlaying=!0}}';

    function _getKey(string memory key) internal view returns (address result) {
        (result) = abi.decode(
            vm.parseJson(configFile, string.concat(".", key)),
            (address)
        );
    }

    function run() public {
        uint256 chainID = vm.envUint("CHAIN_ID");
        console.log("CHAIN_ID", chainID);
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        configFile = vm.readFile(
            string.concat("./addresses/", Strings.toString(chainID), ".json")
        );

        address tokenImpl = _getKey("FixedPriceTokenImpl");
        address ethFSAdapter = _getKey("ETHFSAdapter");
        address holderInteractor = _getKey("HolderInteractor");

        console2.log("~~~~~~~~~~ Token Impl ~~~~~~~~~~~");
        console2.logAddress(tokenImpl);

        console2.log("~~~~~~~~~~ ETHFS Adapter ~~~~~~~~~~~");
        console2.logAddress(ethFSAdapter);

        console2.log("~~~~~~~~~~ Holder Interactor ~~~~~~~~~~~");
        console2.logAddress(holderInteractor);

        vm.startBroadcast(deployerPrivateKey);

        FixedPriceToken token = FixedPriceToken(TOKEN_TO_UPGRADE);
        /*
        token.upgradeTo(tokenImpl);
        token.addImport(
            IHTMLRenderer.FileType({
                name: "runtimeScripts-0.0.2.js",
                fileSystem: ethFSAdapter,
                fileType: 1
            })
        );
        token.setInteractor(holderInteractor);
        */
        token.setScript(SCRIPT_UPGRADE);

        vm.stopBroadcast();

        string memory filePath = string(
            abi.encodePacked("deploys/", chainID.toString(), ".version12.txt")
        );

        vm.writeLine(
            filePath,
            string(
                abi.encodePacked(
                    "FixedPriceToken Upgrade implementation: ",
                    addressToString(tokenImpl)
                )
            )
        );
    }

    function addressToString(
        address _addr
    ) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(_addr)) / (2 ** (8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", string(s)));
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
