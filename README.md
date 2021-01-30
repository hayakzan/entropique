# entropique
A music information retrieval tool written in SuperCollider. Its main function is to extract temporal information from sound by creating rhythmic onsets from considerable changes in the timbral profile, measured by spectral entropy.

entropique uses Pablo DiLiscia, Juan Pampin, and Pete Moss's ATS (Analysis, Transformation, Synthesis) based on a sinusoidal plus critical-band noise model. An ATS file is provided here for testing along with its correspondent audio file (more will be added). In order to create your own ATS files, visit https://sourceforge.net/projects/atsa/files/, where the source as well as an OS X binary can be found (binary requires XQuartz https://www.xquartz.org/). The SuperCollider interface for using ATS files is written by Josh Parmenter, included in his Unit Generator library, JoshUGens.
