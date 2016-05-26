# Pupillometry Analyzer
This short script can be used to analyse pupillometry raw data saved in a wks-file. It analyzes the timeseries and creates informative figures and saves all relevant information for further analysis in xls-files.

This script runs on MATLAB or [Octave](https://www.gnu.org/software/octave/). If you use Octave, than you also need the folder `sgolay_functions` under https://github.com/miykael/pupillometryAnalyzer.

# What do you need to know to start








%%%
% Script relevant variables
refreshrate = 60.0;         % Sampling rate of the eye tracker [Hz]
preinterval=250.0;          % time interval to consider before stimulation [ms]
postinterval=5000.0;        % time interval to consider after stimulation [ms]
pupilSpeedThreshold = .04;  % maximal possible pupil dilation between timepoints [in percentage]
noBlinkingWindow = 15;      % number of consecutive sampling points where no blinking should occure
stdDropMultiplier = 2;      % how many standard deviations has a value to be below the baseline to count as the drop point
recoveryTime = 6000.0;      % time point of relevant recovery point
sgolayOrder = 3;            % Savitzky-Golay Filter: order of the polynom
sgolayWindow = 15;          % Savitzky-Golay Filter: length of window to consider (in sampling points)

%%%
% Condition relevant variables

% Condition Names: First value is file specific identifier, rest of array are condition names
conditions.con1.name = {'_session1_','cond01','cond02','cond03','cond04','cond05','cond06'};
conditions.con2.name = {'_session2_','cond01','cond02','cond03','cond04','cond05'};
conditions.con3.name = {'_session3_','cond01','cond02','cond03'};
conditions.con4.name = {'_session4_','cond01','cond02'};

% Condition ID: The step number specifies which protocol step represents a flash / stimulation
conditions.con1.step = [2, 4, 6, 8, 10, 12];
conditions.con2.step = [3, 5, 7, 9, 11];
conditions.con3.step = [2, 4, 6];
conditions.con4.step = [2, 4];

















# How does the script work

**First**, it reads the WKS-file and reads out relevant information such as pupil width and marker onset.

**Second**, it selects only relevant markers (according the step variables on [line 37](https://github.com/miykael/pupillometryAnalyzer/blob/master/read_wks.m#L37)).

**Third**, it plots an overview figure (as seen below) that shows pupil width over the whole timecourse. Highlighted in red are the relevant markers.
<img src="static/plot_Overview.png">

**Forth**, it extracts single events from the timecourse and transforms the values to percentage signal change. This is done by dividing the event by the average of the prestimuli period. Afterwards it creates a figure of this raw timecourse.
<img src="static/plot1_raw.png">

**Fifth**, it corrects for eyeblinks according the parameters `pupilSpeedThreshold` and `noBlinkingWindow`. It than creates a figure of this eyeblink corrected timecourse.
<img src="static/plot2_corrected.png">

**Sixth**, it smooths the data with a Savitzky-Golay function.

**Seventh**, it calculates droppoint, minimas and recovery point and creates a figure of the smoothed timecourse, showing the location of the droppoint and minimas.
<img src="static/plot3_smoothed.png">

**Ninth**, it saves all the output into a mat file and an xls-file, that can be used for further analysis.
<img src="static/xls_output.png">
