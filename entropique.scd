///////////////////////////////////////////////////////////////////////////////////////////
//entropique--a music information retrieval tool
///////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////
//TOSOLVE: aesthetics... add the time domain, as well as pitch/rhythm and entropy
//
//TODO: add entropy analysis as well as a different graph
// dialogue for .aiff selection
// scale the ranges of window elements according to the pitch/temporal ranges
///////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////
//Entire system
/////////////////////////////////////////////////////
(
// a = AtsFile.new("/Users/rikyu/Desktop/PORTFOLIO/sine.ats".standardizePath).load;
b = Buffer.read(s,"/Users/rikyu/Desktop/PORTFOLIO/rec.aiff".standardizePath);

~businVal = Bus.control(s, 1); //we don't need this and the SynthDef...what's the issue with normal functions?
~atsFrame = Array[0]; //this list has to be populated with frames!!!
~timeArray = Array.new;
~freqs = Array.new;
~entArray = List.new;
~entTimearray = Array.new;

//OSCresponder is deprecated, but at the moment cannot get newer OSC responders working...TODO:get them working
~o1 = OSCresponder(nil, 'the_answer', { |t, r, msg|
	~timeArray.add(~time.time); //add to the time array
	~atsTime = (~time.time.round(0.05)/0.05 + 1);
	~frameNo = "ATS frame no: " ++ ~atsTime;
	~frameNo.postln; //post the frame numbertime
	~atsFrame.add(~atsTime);
~freqs.add(~atsBuf.getFrameFreq(~atsFrame.last).flat);
/*	t.postln;*/
}).add;

~o2 = OSCdef(\new, {|msg, time, addr, recvPort| [~entArray.add(msg[3]), ~entTimearray.add(time)]}, '/msg1');
)


(
var atsFile, enView, openButton, atsBuf, atsPath, atsDispButton, entDispButton, win, atsDisp;

~loadATS = Routine({
fork {
	Synth(\rhythm).waitForFree;
	0.1.wait;
	"done.".postln;
	0.1.wait;
	AppClock.play(~refRout.reset);
		};
});


//GUI
win = Window("Spectrum and Spectrogram", Rect(20, 4000, 1260, 960), false).front;
win.view.background_(Color.grey);
win.alpha_(0.98);
win.onClose = {Buffer.freeAll; "Eyvallah".postln;"".postln};

h = EnvelopeView(win, Rect(30, 20, 1200, 100))
    .thumbSize_(0)
.drawLines_(false)
    .fillColor_(Color.black)
    .drawRects_(true)
.gridOn_(true)
.grid_(-1@1)
.value_([[0], [0]]).setEditable(0,false);

// entropy display
~entDisp = Plotter.new(bounds: Rect(30, 410, 1200, 100),parent: win);
~entDisp.value = [0];

openButton = Button.new(win, Rect(30, 0, 130, 20)) //will also select the aiff file LATER
.states_([["Select ATS file", Color.black, Color.new(0.63915638923645, 0.61455166339874, 0.3189784526825)]])
.action_({
	Dialog.openPanel(
		okFunc: { |path|
			atsPath = path;
			~atsBuf = AtsFile.new(path, s);
		},
		cancelFunc: {"cancelled"}
	);
});

// ATS Analysis Button
atsDispButton= Button.new(win, Rect(250, 120, 250, 30))
.states_([["Extract pitch 'n' rhythm",Color.black, Color.new(0.76396951675415, 0.87935035228729, 0.62494311332703)]])
.action_({
	~time = OSCSched.new; //actual time, STARTS HERE
	AppClock.play(~loadATS.reset);
	~freqs = [ ];
	~atsFrame = Array[0];
});


// Entropy Button
~entDispButton= Button.new(win, Rect(500, 120, 250, 30))
.states_([["Analyze entropy",Color.black, Color.new(0.76396951675415, 0.87935035228729, 0.62494311332703)]])
.action_({
	AppClock.play(~loadEnt.reset);
});


SynthDef(\rhythm, {
	var in, out;
	var	fft, entropy, amplitude, rMax, rMaxThres;
	var time, timeArray;
	var rMaxThr;
	var frameNo;

in = BufRd.ar(1, b, Line.ar(0, BufFrames.kr(b), BufDur.kr(b), doneAction: 2)); //2 is the key
	amplitude = Amplitude.kr(in);
	fft = FFT(LocalBuf(1024), in);
	entropy = SpectralEntropy.kr(fft, 1024, 1);//1 band = full spectrum's entropy

	entropy = entropy * (amplitude.min(0.2)*5.0); //scale by amplitude to avoid low amplitude noise issues

	rMaxThr = 0.5;
	// rMaxThr = 0.01;
	rMax = RunningMax.kr(entropy, Impulse.kr(200)); //tracks the highest values of entropy

	Out.kr(~businVal, rMax); //send to the bus WE'RE NOT USING THIS!!!

	//send the vals to the client side in order to collect them
	SendReply.kr(
		rMax > rMaxThr, // threshold: whenever entropy value passes this value, send a trig
		'/the_answer',
			values: rMax,
		//for rhythm this only serves as a trigger. but entropy graph, we need these values
		replyID: 0
	);
}).add;

SynthDef(\entropy, {
	var in, buf, fft, entropy;
	in = PlayBuf.ar(1, b, BufRateScale.kr(b), loop: 0.0, doneAction: 2); //or Done.freeSelf

	fft = FFT(LocalBuf(2**11), in);

	entropy=SpectralEntropy.kr(fft,2**11,1);    //one output band (so full spectrum's entropy)

	Out.kr(~businVal, entropy); //send to the bus WE'RE NOT USING THIS!!!

	SendReply.kr(
		Impulse.kr(400),
		'/msg1',
		entropy;
	);
	entropy.poll;
}).add;

~loadEnt = Routine({
	Synth(\entropy).waitForFree;
	0.1.wait;
	"done.".postln;
	0.1.wait;
		~entDisp.value = ~entArray.asArray;
		0.1.wait;
		~entDisp.refresh;
		~entDisp.domainSpecs = [0, b.duration, \lin,0,0,"secs"].asSpec; ~entDisp.refresh;
	});


~refRout = Routine({
~enView = EnvelopeView(win, Rect(30, 20, 1200, 100))
    .thumbSize_(12)
.drawLines_(false)
    .fillColor_(Color.black)
    .drawRects_(true)
.gridOn_(true)
.grid_(-1@1)
	.value_([~atsFrame.linlin(0,80,0,2), ~freqs.flat.linlin(0,800,0,1)]).setEditable(0,false); //add linlin with the highest value
});



~timeArray = ~timeArray.flat;
~atsFrame = ~atsFrame.drop(1); //why are we using this? so that we would know what rhythmic change comes during what pitch

)





/////////////////////////////////////////////////////
//working GUI
/////////////////////////////////////////////////////

(
~freqs = Array.new;
~atsframe = Array[0]; //this list has to be populated with frames!!!
~pitchData = Array.new;
)


(
var atsFile, enView, openButton, atsBuf, atsPath, atsDispButton, win, atsDisp;

//init ats
// atsFile = AtsFile.new("/Users/rikyu/Desktop/PORTFOLIO/sine.ats".standardizePath).load;

~loadATS = Routine({
~atsframe.size.do({|i|
	~freqs = atsBuf.getFrameFreq(~atsframe[i]).flat; //frame list
	~pitchData.add(~freqs[i]);
	});
~enView = EnvelopeView(win, Rect(30, 20, 1200, 100))
    .thumbSize_(10)
.drawLines_(false)
    .fillColor_(Color.black)
    .drawRects_(true)
.gridOn_(true)
.grid_(-1@1)
.value_([[0], ~pitchData.linlin(0,800,0,1)]).setEditable(0,false);
});



/////////it gives getFrameFreq not understood because file is not loaded/////////////

//GUI
win = Window("Spectrum and Spectrogram", Rect(20, 4000, 1260, 960), false).front;
win.view.background_(Color.grey);
win.alpha_(0.98);
win.onClose = {Buffer.freeAll; "Eyvallah".postln;"".postln};

h = EnvelopeView(win, Rect(30, 20, 1200, 100))
    .thumbSize_(0)
.drawLines_(false)
    .fillColor_(Color.black)
    .drawRects_(true)
.gridOn_(true)
.grid_(-1@1)
.value_([[0], [0]]).setEditable(0,false);


openButton = Button.new(win, Rect(30, 0, 130, 20))
.states_([["Select ATS file", Color.black, Color.new(0.63915638923645, 0.61455166339874, 0.3189784526825)]])
.action_({
	Dialog.openPanel(
		okFunc: { |path|
			atsPath = path;
			atsBuf = AtsFile.new(path, s);
		},
		cancelFunc: {"cancelled"}
	);
});

// ATS Analysis Button
atsDispButton= Button.new(win, Rect(250, 120, 250, 30))
.states_([["Analyze spectrum",Color.black, Color.new(0.76396951675415, 0.87935035228729, 0.62494311332703)]])
.action_({
	AppClock.play(~loadATS.reset); //or value? or value AND reset?
	~pitchData = [ ];
});

//entropy functions WE NEED THIS FOR TIMBRE, NOT FOR RHYTHM
~loadEnt = Routine({
		~entDisp.value = ~entarray.asArray;
		0.0001.wait;
		~entDisp.refresh;
		~entDisp.value = ~entarray.asArray;
		~entDisp.domainSpecs = [0, ~buf.duration, \lin,0,0,"secs"].asSpec; ~entDisp.refresh;
	});

)
