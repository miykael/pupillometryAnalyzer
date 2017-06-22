# Pupillometry Analyzer

This short script can be used to analyse pupillometry raw data saved in a wks-file. It analyzes the timeseries and creates informative figures and saves all relevant information for further analysis in xls-files.

This script runs on MATLAB or [Octave](https://www.gnu.org/software/octave/). If you use Octave, than you also need the folder `sgolay_functions` under https://github.com/miykael/pupillometryAnalyzer.


# Citation

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.580285.svg)](https://doi.org/10.5281/zenodo.580285)

If you used Pupillometry Analyzer in your project, please cite as: Notter, Michael P., & Murray, Micah M. (2017). Pupillometry Analyzer: a lightweight matlab tool to pre-process pupillometry data. Zenodo. [http://doi.org/10.5281/zenodo.580285](http://doi.org/10.5281/zenodo.580285).


# How does the script work?

**First**, it reads the WKS-file and reads out relevant information such as pupil width and marker onset.

**Second**, it selects only relevant markers (according to the step variables on [line 37](https://github.com/miykael/pupillometryAnalyzer/blob/master/read_wks.m#L37)).

**Third**, it plots an overview figure (as seen below) that shows pupil width over the whole timecourse. Highlighted in red are the relevant marker onsets.
<img src="static/plot_Overview.png">

**Forth**, it extracts single epochs from the timecourse and transforms the values to percentage signal change. This is done by dividing the time-course of the whole epoch by the average of the pre-stimuli period. Afterwards, the epochs will be plotted as a raw timecourse.
<img src="static/plot1_raw.png">

**Fifth**, all epoch time-courses are inspected and corrected for eye blinks. Eye blinks are defined as periods where the time-course abruptly changes in more than 4% (`pupilSpeedThreshold`). The stop of the blink period is defined as another abrupt change of at least 4% in the opposite direction, followed by a "non blink period" of at least `noBlinkingWindow` time points. Those blink periods are then linearly interpolated between their onsets and offsets. Blink corrected figures of the timecourse are created.
<img src="static/plot2_corrected.png">

**Sixth**, epoch time-courses are smoothed with MATLAB's Savitzky-Golay function, by using a 3rd order (`sgolayOrder`) polynomial and a window length of `sgolayWindow` time-points.

**Seventh**, amplitude and latency of informative time-points such as drop-point, minima and recovery point àre computed for each epoch. A  drop-point is defined as the first time-point where the signal drops for more than two (i.e. `stdDropMultiplier`) pre-stimuli standard deviation below the stimuli onset amplitude for a duration of at least 1250ms (i.e. 5 times pre-stimuli duration). Minima is defined as the minima of the epoch time-course between 0ms and 3000ms (3 times the refresh rate of your data) after stimuli onset. The recover point represents a time-point of interest at 6000ms (`recoveryTime`) after stimuli onset. Figures of the smoothed time course with highlighted drop-point and minima are created.
<img src="static/plot3_smoothed.png">

**Ninth**, all relevant information are saved as outputs into a mat- and an xls-file. Those file can than be used for further analysis.
<img src="static/xls_output.png">


# What do you need to know to start?

All the things you need to change so that the script runs according your case should be within the first 45 lines.

**First**, make sure that you set `experimentPath` to the parent folder of your experiment (Don't forget the '\' at the end of the path) and specify the path to the wks-files with `wksfilepath`.

**Second**, adapt all script relevant variables between line 18-26.

* `pupilSpeedThreshold` and `noBlinkingWindow` are needed to detect and correct for eye blinks. They work as follows: As soon as a timepoint to timepoint pupil dilation differec more than 4% (according to `pupilSpeedThreshold`), than it is seen as an eyeblink. The end of the eyeblink period is seen as the last eyeblink point after which there are no eyeblink points for 15 timepoints (according to `noBlinkingWindow`).
* The "Droppoint" of the epoch timecourse is divined as the point where the timecourse falls for more than 5 pre-interval duration (e.g. 250ms x 5 = 1250ms) below 2 x Standard Deviation (according `stdDropMultiplier`) of the pre-stimuli timecourse.
* `recoveryTime` specifies the timepoint from which amplitude information should be read out and saved into the output xls-file

**Third**, change the `conditions` variable according your conditions. The first string in `conditions.con1.name` specifies the filename string which defines the condition, followed by the individual names of the conditions. The `conditions.con1.step` array specifies which markers of all recorded markers should be considered as relevant.
