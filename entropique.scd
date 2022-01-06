///////////////////////////////////////////////////////////////////////////////////////////
//entropique--a music information retrieval tool
///////////////////////////////////////////////////////////////////////////////////////////
//Place the cursor anywhere between the first pair of parentheses and press Cmd-Return (Ctrl-Enter on the PC)
//A sine wave interrupted by white noise is provided in "files" folder
//Select the audio file and ATS file using the dialogue.
//"Extract rhythm" generates rhythmic onsets. The data will appear in the post window.
//"Analyze entropy" plots the overall entropy profile of the soundfile.


(
var atsFile, enView, fileOpenButton, atsOpenButton, atsBuf, atsPath, atsDispButton, entDispButton, win, atsDisp;


~businVal = Bus.control(s, 1);

~atsFrame = Array[0]; //this list has to be populated with frames
~timeArray = Array.new;
// ~freqs = Array.new;
~amps = Array.new;
~entArray = List.new;
~entTimearray = Array.new;

~o1 = OSCresponder(nil, 'the_answer', { |t, r, msg|
	~timeArray.add(~time.time); //add to the time array
	~atsTime = (~time.time.round(0.05)/0.05 + 1);
	~frameNo = "ATS frame no: " ++ ~atsTime;
	~atsFrame = ~atsFrame.add(~atsTime);
	~atsFrame.postln;
~amps.add(~atsBuf.getFrameAmp(~atsFrame.last).flat);
~atsFrame.remove(0); //drop the placeholder value
	~atsFrame.remove(1.0);
}).add;

~o2 = OSCdef(\new, {|msg, time, addr, recvPort| [~entArray.add(msg[3]), ~entTimearray.add(time)]}, '/msg1');

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
win = Window("Rhythmic info and Entropy analysis", Rect(20, 4000, 1260, 400), false).front;
win.view.background_(Color.grey);
win.alpha_(0.98);
win.onClose = {Buffer.freeAll; "Done".postln;"".postln};

h = EnvelopeView(win, Rect(30, 78, 1200, 100))
    .thumbSize_(0)
.drawLines_(false)
    .fillColor_(Color.black)
    .drawRects_(true)
.gridOn_(true)
.grid_(-1@1)
.value_([[0], [0]]).setEditable(0,false);

// entropy display
~entDisp = Plotter.new(bounds: Rect(30, 250, 1200, 100),parent: win);
~entDisp.value = [0];

fileOpenButton = Button.new(win, Rect(30, 0, 130, 20)) //TODO: will also select the aiff file
.states_([["Select sound file", Color.black, Color.new(0.63915638923645, 0.61455166339874, 0.3189784526825)]])
.action_({
	Dialog.openPanel(
		okFunc: { |path|
			b = Buffer.read(s,path);
		},
		cancelFunc: {"cancelled"}
	);
});

atsOpenButton = Button.new(win, Rect(190, 0, 130, 20)) //TODO: will also select the aiff file
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
atsDispButton= Button.new(win, Rect(30, 50, 250, 30))
.states_([["Extract rhythm",Color.black, Color.new(0.76396951675415, 0.87935035228729, 0.62494311332703)]])
.action_({
	~time = OSCSched.new;
	AppClock.play(~loadATS.reset);
	// ~freqs = [ ];
	// ~atsFrame = Array[0];
});


// Entropy Button
~entDispButton= Button.new(win, Rect(30, 220, 250, 30))
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
	entropy = SpectralEntropy.kr(fft, 1024, 1); //1 band = full spectrum's entropy

	entropy = entropy * (amplitude.min(0.2)*5.0); //scale by amplitude to avoid low amplitude noise issues

	rMaxThr = 1.0;
	// rMaxThr = 0.01;
	rMax = RunningMax.kr(entropy, Impulse.kr(200)); //tracks the highest values of entropy

	Out.kr(~businVal, rMax);
	rMax.poll;

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
	in = PlayBuf.ar(1, b, BufRateScale.kr(b), loop: 0.0, doneAction: 2);

	fft = FFT(LocalBuf(2**11), in);

	entropy = SpectralEntropy.kr(fft,2**11,1);

	Out.kr(~businVal, entropy);

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
~enView = EnvelopeView(win, Rect(30, 78, 1200, 100))
    .thumbSize_(12)
.drawLines_(false)
    .fillColor_(Color.black)
    .drawRects_(true)
.gridOn_(true)
.grid_(-1@1)
	.value_([~atsFrame.linlin(0,~atsFrame.last+1,0,1), Array.fill(~atsFrame.size,0.5)]); /
});
)
~atsFrame.size;



