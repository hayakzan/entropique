# entropique
a music information retrieval tool written in SuperCollider. its main function is to extract temporal information from sound by creating rhythmic offsets from considerable changes in timbral profile, measured by spectral entropy.

it uses Pablo DiLiscia, Juan Pampin, and Pete Moss's ATS (Analysis, Transformation, Synthesis) based on a sinusoidal plus critical-band noise model. ATS files are provided here for testing, in order to create your own ATS files, visit https://sourceforge.net/projects/atsa/files/, where the source as well as an OS X binary can be found (binary requires XQuartz https://www.xquartz.org/). the SuperCollider interface for using ATS files is written by Josh Parmenter, included in his Unit Generator library, JoshUGens.
