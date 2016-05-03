%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Michael Notter, January 2016, email: michaelnotter@hotmail.com

% Path to the project folder
experimentPath='U:\PUPSEO\analyse\';

% Path to the folder containing the WKS-files, relative to the project folder
wksfilepath=[experimentPath,'Puoillometrie\BaR pupillo\'];

% If you use octave, than you need to load the sgolayfilt function from the signal packege,
% or add the path to the signal package folder
addpath([experimentPath,'scripts\signal_package'])

%%%
% Script relevant variables
refreshrate = 60.0;         % Sampling rate of the eye tracker [Hz]
preinterval=250.0;          % time interval to consider before stimulation [ms]
postinterval=7000.0;        % time interval to consider after stimulation [ms]
pupilSpeedThreshold = .04;  % maximal possible pupil dilation between timepoints [in percentage]
noBlinkingWindow = 3;       % number of consecutive sampling points where no blinking should occure
stdDropMultiplier = 2;      % how many standard deviations has a value to be below the baseline to count as the drop point
recoveryTime = 6000.0;      % time point of relevant recovery point
sgolayOrder = 3;            % Savitzky-Golay Filter: order of the polynom
sgolayWindow = 15;          % Savitzky-Golay Filter: length of window to consider (in sampling points)

%%%
% Condition relevant variables

% Condition Names: First value is file specific identifier, rest of array are condition names
conditions.con1.name = {'_rod_','-4 blue','-3.5 blue','-3 blue','-2.5 blue','-2 blue','-1.5 blue'};
conditions.con2.name = {'_cone_','0 red', '1 red', '1.5 red','2 red','2.5 red'};
conditions.con3.name = {'_melanopsin_O','1 blue','1.5 blue','2 blue'};
conditions.con4.name = {'_melanopsin_binoc','2.3 red','2.3 blue'};

% Condition ID: The step number specifies which protocol step represents a flash / stimulation
conditions.con1.step = [2, 4, 6, 8, 10, 12];
conditions.con2.step = [3, 5, 7, 9, 11];
conditions.con3.step = [2, 4, 6];
conditions.con4.step = [2, 4];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% DO NOT CHANGE SCRIPT BELOW %%%%

% Get Name of WKS-files in folder
file_id = dir(strcat(wksfilepath,'*.wks'));
file_id = {file_id.name};

% Go through all WKS-files in wksfilepath folder
for f=1:numel(file_id)

    filename = file_id{f};
    disp(['Analysing File: ', filename])

    % Find the right condition
    for i=1:length(fieldnames(conditions))
        tmp = conditions.(['con',num2str(i)]);
        if findstr(tmp.name{1},filename)
            condition = tmp.name(2:end);
            step = tmp.step;
        end
    end

    % Open and read WKS-file
    fid = fopen([wksfilepath, filename],'rt','n');
    tmp = textscan(fid,'%s','Delimiter','\n');
    tmp = tmp{1};
    fclose(fid);

    % Create output variable
    output = [];
    output.filename = filename;

    % Read Header
    i=1;
    while isempty(strfind(tmp{i},'TotalTime'))
        line=strread(tmp{i}, '%s');

        if isequal(line{2},'TimeStamp')
            output.TimeStamp = [line{4:end}];
        elseif isequal(line{2},'DataFormat')
            output.DataFormat = line{3};
        elseif isequal(line{2},'ScreenSize')
            output.ScreenSize = [line{3},'x',line{4}];
        elseif isequal(line{2},'ViewingDistance')
            output.ViewingDistance = line{3};
        elseif isequal(line{2},'ImageShape')
            output.ImageShape = line{3};
        end
        i=i+1;
    end

    % Read Data Header
    dataheader = strread(tmp{i}, '%s');
    output.dataheader = dataheader;

    % Create column variables (saves both eyes in one variable)
    for j=2:10
        output.(dataheader{j}) = [];
    end
    output.(dataheader{end-1}) = [];
    output.(dataheader{end}) = {};

    % Save Data Values in column variables
    while isempty(strfind(tmp{i},'END'))
        line=strread(tmp{i}, '%s');

        % Read out Frame Rate of Eyes
        if isequal(line{1},'7')
            if isequal(line{3},'Eye1')
                output.Eye1 = str2num(line{end});
            elseif isequal(line{3},'Eye2')
                output.Eye2 = str2num(line{end});
            end
        elseif isequal(line{1},'10')
            for k=2:10
                output.(dataheader{k}) = [output.(dataheader{k}); ...
                                          [str2num(line{k}), str2num(line{k+9})]];
            end
            if isequal(length(dataheader),length(line))
                output.(dataheader{end-1}) = [output.(dataheader{end-1}); ...
                                              str2num(line{end-1})];
                output.(dataheader{end}) = [output.(dataheader{end}); line{end}];
            else
                output.(dataheader{end-1}) = [output.(dataheader{end-1}); ...
                                              str2num(line{end})];
                output.(dataheader{end}) = [output.(dataheader{end}); ' '];
            end
        end
        i=i+1;
    end

    % Get index of stimuli onset and offset
    output.stimuli_onset = find(ismember(output.Marker,'S'));
    output.stimuli_offset = find(ismember(output.Marker,'s'));
    output.stimuli_both = find(ismember(output.Marker,'S,s'));
    output.stimuli_onset = sort([output.stimuli_onset; output.stimuli_both]);
    output.stimuli_offset = sort([output.stimuli_offset; output.stimuli_both]);

    % If 's' is missing, cut off a value of steps and rename conditions
    if length(output.stimuli_onset) < max(step)
        step = step(1:end-1);

        condition ={'cond1'};
        for c=2:length(step)
            condition = [condition ['cond',num2str(c)]];
        end
    end

    % Only keep the values for the flash    
    flash_onset = output.stimuli_onset(step);

    % Plot overview figures
    fig = figure;
    subplot(2,1,1)
    hold on
    plot(output.TotalTime(:,1), output.PupilWidth(:,1),'Color','blue')
    maxwidth=max(output.PupilWidth(:,1));
    for k=1:length(flash_onset)
        ha = area([output.TotalTime(flash_onset(k),1) output.TotalTime(flash_onset(k),1)+1/refreshrate], ...
            [maxwidth maxwidth], 'FaceColor',[1,0,0],'EdgeColor',[1,0,0]);
    end
    title(strrep(filename,'.wks',' - PupilWidth Eye1'),'fontweight','bold');
    ylim([min(output.PupilWidth(:,1)) max(output.PupilWidth(:,1))]);
    xlim([min(output.TotalTime(:,1)) max(output.TotalTime(:,1))]);
    xlabel('time [ms]'); ylabel('PupilWidth Eye1');
    hold off

    subplot(2,1,2)
    hold on
    plot(output.TotalTime(:,2), output.PupilWidth(:,2),'Color',[0,0.5,0])
    maxwidth=max(output.PupilWidth(:,2));
    for k=1:length(flash_onset)
        ha = area([output.TotalTime(flash_onset(k),2) output.TotalTime(flash_onset(k),2)+1/refreshrate], ...
            [maxwidth maxwidth], 'FaceColor',[1,0,0],'EdgeColor',[1,0,0]);
    end
    title(strrep(filename,'.wks',' - PupilWidth Eye2'),'fontweight','bold');
    ylim([min(output.PupilWidth(:,2)) max(output.PupilWidth(:,2))]);
    xlim([min(output.TotalTime(:,2)) max(output.TotalTime(:,2))]);
    xlabel('time [s]'); ylabel('PupilWidth Eye2');
    hold off

    print(fig,'-dpng','-r300',[wksfilepath,'plot_Overview_',strrep(filename,'.wks','.png')])
    close(fig);

    % Check if monocular recording; if so, set irrelevant eye to 1.0
    if findstr('_OD', filename)
        output.PupilWidth(:,2) = output.PupilWidth(:,1);
    end
    if findstr('_OG', filename)
        output.PupilWidth(:,1) = output.PupilWidth(:,2);
    end

    %%%
    % Create Epochs
    pretime=(preinterval/1000.0)*refreshrate;
    posttime=(postinterval/1000.0)*refreshrate;

    epochs.Eye1 = [];
    epochs.Eye2 = [];
    for i=1:length(flash_onset)
        timepoint=flash_onset(i);
        timerange=timepoint-pretime:timepoint+posttime;

        for j=1:2
            % get epoch
            tmp=output.PupilWidth(timepoint-pretime:timepoint+posttime, j);

            % calculate percentage to baseline
            baselineshift=mean(tmp(1:pretime));
            epochs.(['Eye',num2str(j)]) = [epochs.(['Eye',num2str(j)]) tmp/baselineshift];
        end
    end

    % Correct for eyeblinks
    for k=1:2
        epochs.(['Eye',num2str(k),'_corrected']) = [];
        for e=1:size(epochs.(['Eye',num2str(k)]),2)
            signal=epochs.(['Eye',num2str(k)])(:,e);
            outliers = abs(diff(signal))>pupilSpeedThreshold;
            interpolStart = [];
            interpolStop = [];
            tmp=0;
            counter=0;
            for i=1:length(outliers)
                if tmp == 0
                    if outliers(i) == 1
                        interpolStart = [interpolStart i];
                        tmp = -1;
                    end
                elseif tmp == -1
                    if outliers(i) == 0
                        tmp = i;
                        counter = 1;
                    end
                else
                    if outliers(i) == 1
                        tmp = -1;
                    elseif counter == noBlinkingWindow
                        interpolStop = [interpolStop tmp];
                        tmp = 0;
                    else
                        counter = counter + 1;
                    end
                end
            end

            if isempty(interpolStop)
                interpolStop = length(signal);
            end

            %drop the last interpolation start if the the last interpolation stop doesn't exist
            if length(interpolStop) < length(interpolStart)
                interpolStart = interpolStart(1:end-1);
            end
            interpolStep = interpolStop-interpolStart;
            
            for j=1:length(interpolStep)
                startID = interpolStart(j);
                stopID = interpolStop(j);
                stepsize = diff([signal(startID),signal(stopID)])/interpolStep(j);
                if stepsize == 0
                    signal(startID:stopID) = signal(startID);
                else
                    signal(startID:stopID) = signal(startID):stepsize:signal(stopID);
                end
            end
            epochs.(['Eye',num2str(k),'_corrected']) = [epochs.(['Eye',num2str(k),'_corrected']) signal];
        end
    end

    % Smooth data with a Savitzky-Golay
    % The sgolayfilt function can be used on octave if you use the package called 'signal'
    epochs.Eye1_smoothed = sgolayfilt(epochs.Eye1_corrected,sgolayOrder,sgolayWindow);
    epochs.Eye2_smoothed = sgolayfilt(epochs.Eye2_corrected,sgolayOrder,sgolayWindow);

    % Calculate drop point and minima information
    for k=1:2
        epochs.(['Eye',num2str(k),'_droppoint']) = [];
        epochs.(['Eye',num2str(k),'_minima']) = [];
        for e=1:size(epochs.(['Eye',num2str(k),'_smoothed']),2)

            curve = epochs.(['Eye',num2str(k),'_smoothed'])(:,e);

            % Find relevant valley point
            valley_id=find(curve==min(curve(pretime:pretime+3*refreshrate)));
            valley_latency=(valley_id-pretime)/refreshrate*1000;
            valley_amplitude=curve(valley_id);

            % Find relevant drop point
            % (first point where signal is below X*preSTD for more than the duration of 5*baseline)
            dropline=find(curve(1:5*pretime)<(mean(curve(1:pretime))-stdDropMultiplier*std(curve(1:pretime))));
            consecutive_id=[true;diff(dropline(:))~=1 ];
            consecutive_id=find(consecutive_id);
            if isempty(dropline)
                drop_id=1;
            else
                drop_id=dropline(consecutive_id(end));
            end
            drop_latency=(drop_id-pretime)/refreshrate*1000;
            drop_amplitude=curve(drop_id);

            epochs.(['Eye',num2str(k),'_droppoint']) = [epochs.(['Eye',num2str(k),'_droppoint']) [drop_latency; drop_amplitude]];
            epochs.(['Eye',num2str(k),'_minima']) = [epochs.(['Eye',num2str(k),'_minima']) [valley_latency; valley_amplitude]];
        end
    end

    % Calculate recovery point after x seconds
    rectime=(recoveryTime/1000.0)*refreshrate;
    for k=1:2
        epochs.(['Eye',num2str(k),'_recovery']) = [];
        for e=1:size(epochs.(['Eye',num2str(k),'_smoothed']),2)
            curve = epochs.(['Eye',num2str(k),'_smoothed'])(:,e);
            epochs.(['Eye',num2str(k),'_recovery']) = [epochs.(['Eye',num2str(k),'_recovery']) [curve(rectime)]];
        end
    end


    %%%
    % Plot figures

    % Plot Epochs (raw data)
    xaxis = (-preinterval:1000./refreshrate:postinterval);
    fig = figure;
    subplot(2,1,1)
    hold on
    plot(xaxis, epochs.Eye1)
    title(strrep(filename,'.wks',' - PupilWidth Eye1'),'fontweight','bold');
    ylim([min(min(epochs.Eye1))*.95 max(max(epochs.Eye1))*1.05]);
    xlim([-preinterval postinterval]);
    xlabel('time [ms]'); ylabel('PupilWidth Eye1');
    legend(condition, 'Location','southeast');
    hold off

    subplot(2,1,2)
    hold on
    plot(xaxis, epochs.Eye2)
    title(strrep(filename,'.wks',' - PupilWidth Eye2'),'fontweight','bold');
    ylim([min(min(epochs.Eye2))*.95 max(max(epochs.Eye2))*1.05]);
    xlim([-preinterval postinterval]);
    xlabel('time [ms]'); ylabel('PupilWidth Eye2');
    legend(condition, 'Location','southeast');
    hold off

    print(fig,'-dpng','-r300',[wksfilepath,'plot_Epoch_',strrep(filename,'.wks',''),'_1RAW.png'])
    close(fig);

    % Plot Epochs (corrected data)
    xaxis = (-preinterval:1000./refreshrate:postinterval);
    fig = figure;
    subplot(2,1,1)
    hold on
    plot(xaxis, epochs.Eye1_corrected)
    title(strrep(filename,'.wks',' - PupilWidth Eye1'),'fontweight','bold');
    ylim([min(min(epochs.Eye1_corrected))*.95 max(max(epochs.Eye1_corrected))*1.05]);
    xlim([-preinterval postinterval]);
    xlabel('time [ms]'); ylabel('PupilWidth Eye1');
    legend(condition, 'Location','southeast');
    hold off

    subplot(2,1,2)
    hold on
    plot(xaxis, epochs.Eye2_corrected)
    title(strrep(filename,'.wks',' - PupilWidth Eye2'),'fontweight','bold');
    ylim([min(min(epochs.Eye2_corrected))*.95 max(max(epochs.Eye2_corrected))*1.05]);
    xlim([-preinterval postinterval]);
    xlabel('time [ms]'); ylabel('PupilWidth Eye2');
    legend(condition, 'Location','southeast');
    hold off

    print(fig,'-dpng','-r300',[wksfilepath,'plot_Epoch_',strrep(filename,'.wks',''),'_2corrected.png'])
    close(fig);


    % Plot Epochs (smoothed data)
    xaxis = (-preinterval:1000./refreshrate:postinterval);
    fig = figure;
    subplot(2,1,1)
    hold on
    plot(xaxis, epochs.Eye1_smoothed)
    title(strrep(filename,'.wks',' - PupilWidth Eye1'),'fontweight','bold');
    ylim([min(min(epochs.Eye1_smoothed))*.95 max(max(epochs.Eye1_smoothed))*1.05]);
    xlim([-preinterval postinterval]);
    xlabel('time [ms]'); ylabel('PupilWidth Eye1');
    legend(condition, 'Location','southeast');

    colorOrder = get(gca, 'ColorOrder');
    for i=1:size(epochs.Eye1_droppoint, 2)
        drop_latency = epochs.Eye1_droppoint(1,i);
        drop_amplitude = epochs.Eye1_droppoint(2,i);
        valley_latency = epochs.Eye1_minima(1,i);
        valley_amplitude = epochs.Eye1_minima(2,i);

        currentColor = colorOrder(mod(i,8),:);
        descr = {['t = ',num2str(drop_latency),'ms'];
                 ['a = ',num2str(drop_amplitude)]};
        text(drop_latency, drop_amplitude, 'o', 'color', currentColor, 'fontweight', 'bold', 'fontsize', 10, 'HorizontalAlignment', 'center');
        descr = {['t = ',num2str(valley_latency),'ms'];
                 ['a = ',num2str(valley_amplitude)]};
        text(valley_latency, valley_amplitude, 'o', 'color', currentColor, 'fontweight', 'bold', 'fontsize', 10, 'HorizontalAlignment', 'center');
    end
    hold off

    subplot(2,1,2)
    hold on
    plot(xaxis, epochs.Eye2_smoothed)
    title(strrep(filename,'.wks',' - PupilWidth Eye2'),'fontweight','bold');
    ylim([min(min(epochs.Eye2_smoothed))*.95 max(max(epochs.Eye2_smoothed))*1.05]);
    xlim([-preinterval postinterval]);
    xlabel('time [ms]'); ylabel('PupilWidth Eye2');
    legend(condition, 'Location','southeast');

    colorOrder = get(gca, 'ColorOrder');
    for i=1:size(epochs.Eye2_droppoint, 2)
        drop_latency = epochs.Eye2_droppoint(1,i);
        drop_amplitude = epochs.Eye2_droppoint(2,i);
        valley_latency = epochs.Eye2_minima(1,i);
        valley_amplitude = epochs.Eye2_minima(2,i);

        currentColor = colorOrder(mod(i,8),:);
        descr = {['t = ',num2str(drop_latency),'ms'];
                 ['a = ',num2str(drop_amplitude)]};
        text(drop_latency, drop_amplitude, 'o', 'color', currentColor, 'fontweight', 'bold', 'fontsize', 10, 'HorizontalAlignment', 'center');
        descr = {['t = ',num2str(valley_latency),'ms'];
                 ['a = ',num2str(valley_amplitude)]};
        text(valley_latency, valley_amplitude, 'o', 'color', currentColor, 'fontweight', 'bold', 'fontsize', 10, 'HorizontalAlignment', 'center');
    end
    hold off

    print(fig,'-dpng','-r300',[wksfilepath,'plot_Epoch_',strrep(filename,'.wks',''),'_3smoothed.png'])
    close(fig);


    %%%
    % Save output to MAT file
    output.epochs = epochs;
    save([wksfilepath, 'matfile_', strrep(filename,'.wks','.mat')], 'output');


    %%%
    % Save output to xls file
    fid = fopen([wksfilepath, 'table_', strrep(filename,'.wks','.xls')],'w');
    header = condition;

    % Save the smoothed data information
    for e=1:2
        fprintf(fid, ['Eye',num2str(e),' - Smoothed Data\n\n']);

        fprintf(fid, ['Significant Points,',strjoin(header,','),'\n']);

        for l=1:2
            if l == 1
                pointtype = '_droppoint';
            else
                pointtype = '_minima';
            end

            tmp = ['amplitude',pointtype];
            ampli = epochs.(['Eye', num2str(e), pointtype])(2,:);
            for j=1:length(ampli)
                tmp = [tmp ',' num2str(ampli(j))];
            end
            fprintf(fid, [tmp,'\n']);

            tmp = ['latency',pointtype];
            laten = epochs.(['Eye', num2str(e), pointtype])(1,:);
            for j=1:length(laten)
                tmp = [tmp ',' num2str(laten(j))];
            end
            fprintf(fid, [tmp,'\n']);
        end
        fprintf(fid, '\n');

        fprintf(fid, ['Recovery at ',num2str(recoveryTime),'ms,',strjoin(header,','),'\n']);
        tmp = ['amplitude'];
        amplty = epochs.(['Eye', num2str(e), '_recovery'])(1,:);
        for j=1:length(amplty)
            tmp = [tmp ',' num2str(amplty(j))];
        end
        fprintf(fid, [tmp,'\n']);
        fprintf(fid, '\n');

        % Add time axis to excel output
        tmp = {'Time [ms]'};
        samplingRate = 1000.0/refreshrate;
        for t=-preinterval:samplingRate:postinterval
            tmp = [tmp num2str(t)];
        end
        fprintf(fid, [strjoin(tmp,','),'\n']);

        for i=1:size(epochs.(['Eye',num2str(e), '_smoothed']),2)

            tmp = [header(i)];
            signal = epochs.(['Eye',num2str(e), '_smoothed'])(:,i);
            for j=1:length(signal)
                tmp = [tmp num2str(signal(j))];
            end
            fprintf(fid, [strjoin(tmp,','),'\n']);
        end

        fprintf(fid, '\n\n');
    end

    % Save the corrected and raw data information
    for e=1:2
        fprintf(fid, ['Eye',num2str(e),' - Corrected Data\n\n']);

        % Add time axis to excel output
        tmp = {'Time [ms]'};
        samplingRate = 1000.0/refreshrate;
        for t=-preinterval:samplingRate:postinterval
            tmp = [tmp num2str(t)];
        end
        fprintf(fid, [strjoin(tmp,','),'\n']);

        for i=1:size(epochs.(['Eye',num2str(e), '_corrected']),2)

            tmp = [header(i)];
            signal = epochs.(['Eye',num2str(e), '_corrected'])(:,i);
            for j=1:length(signal)
                tmp = [tmp num2str(signal(j))];
            end
            fprintf(fid, [strjoin(tmp,','),'\n']);
        end

        fprintf(fid, '\n\n');
    end

    for e=1:2
        fprintf(fid, ['Eye',num2str(e),' - Raw Data\n\n']);

        % Add time axis to excel output
        tmp = {'Time [ms]'};
        samplingRate = 1000.0/refreshrate;
        for t=-preinterval:samplingRate:postinterval
            tmp = [tmp num2str(t)];
        end
        fprintf(fid, [strjoin(tmp,','),'\n']);

        for i=1:size(epochs.(['Eye',num2str(e)]),2)

            tmp = [header(i)];
            signal = epochs.(['Eye',num2str(e)])(:,i);
            for j=1:length(signal)
                tmp = [tmp num2str(signal(j))];
            end
            fprintf(fid, [strjoin(tmp,','),'\n']);
        end

        fprintf(fid, '\n\n');
    end
    fclose(fid);

    % Free up some memory by deleting heavy variables and closing windows
    clear curve epochs output signal;
    close all;

end
