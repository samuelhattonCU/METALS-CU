function vic_pip = get_vic_pip
    % assumes it's in a "Data Export" directory already

    file_list = ls('vic*.csv');
    [l,~] = size(file_list);
    if isempty(file_list)
        here = pwd;
        disp("No 'vic*.csv' files found in " + string(here) + ', skipping.')
        vic_pip = [];
        return
    end
    if l > 1
        found = false;
        num = 0;
        while ~found && num <= l
            num = num + 1;
            test = file_list(num,:);
            if ~contains(test,"_")
                if (count(test,"-") == 2) && contains(test,"sample") && contains(test,"specimen")
                    found = true;
                end
            end
        end
        file_name = file_list(num,:);
    else
        file_name = file_list(1,:);
    end
    
    % Load data
    
    warning off
    data = readtable(file_name,"NumHeaderLines",1,"VariableNamesLine",1);
    warning on

    % Trim out any calibration images

    bad_rows = contains(data.Filename_0_1,"-cal-");
    data(bad_rows,:) = [];

    % Take columns we want to keep:
    if any("PIP" == string(data.Properties.VariableNames))
        vic_pip = [data(:,"Count"),data(:,"Time_0_1"),data(:,"PIP")];
    else
        warning("No PIP signal found in '" + file_name + "', skipping")
        vic_pip = [];
        return
    end
    
    % % try to find if the vic data started and stopped ever, and adjust the
    % % time:
    % 
    % buffer = 4;
    % 
    % time = vic_pip.Time_0_1(buffer:end);
    % 
    % timediff = diff(time);
    % jumpLocs = find(round(timediff,1) > 0.2);
    % if sum(jumpLocs)
    %     warning("Attempting to adjust VIC Time to account for a jump. " + string(file_name))
    %     jumpLoc = jumpLocs(1);
    %     jumpStep = time(jumpLoc) - time(jumpLoc-1);
    %     jumpError = jumpStep - 0.2;
    %     time(jumpLoc:end) = time(jumpLoc:end) - jumpError;
    %     vic_pip.Time_0_1(buffer:end) = time;
    % end
    


    % find pips!
    signal_threshold_volts = 4.85; % May want to lower this! 
    closed_threshold_volts = 0.15;
    signal_strt = find(vic_pip.PIP > signal_threshold_volts,1);
    answer = "def";
    while ~strcmp(answer,"Skip")
        if isempty(signal_strt)
            answer = questdlg("No PIP signal found at a threshold of " + string(signal_threshold_volts) + "V, would you like to skip, or try again with a new threshold value?","No PIP Found","Skip","Set new threshold","Skip");
            switch answer
                case "Skip"
                    warning("No PIP signal found in '" + file_name + "', skipping")
                    vic_pip = [];
                    return
                case "Set new threshold"
                    new_thresh = inputdlg("Please set a new PIP threshold value in Volts.","Input New Threshold");
                    new_thresh = new_thresh{1,1};
                    if ~isa(new_thresh,"double")
                        new_thresh = str2num(new_thresh);
                    end
                    signal_threshold_volts = new_thresh;
                    signal_strt = find(vic_pip.PIP > signal_threshold_volts(1),1);
            end
        else
            answer = "Skip";
        end
    end
    % idxs = find(vic_pip.PIP(signal_strt:end) < closed_threshold_volts);
    % 
    %     %%% Note this doesn't look for more than the FIRST PIP but it
    %     %%% should avoid noise at the beggining of a test by waiting for
    %     %%% the signal to stabalize before starting to look for pips.
    % pip_loc = idxs(1);

    %%% The above doesn't make sense to me anymore? Maybe it was noise from
    %%% the button. I'm working with a sample where we just
    %%% unplugged/plugged the whole cord, so maybe the signal is more
    %%% clear; anyways signal_strt gave a good index to sync with, but
    %%% pip_loc = idxs(1) ended up giving like 2 as the index, which
    %%% totally doesn't work. - Sam Hatton, 1/22/25

    %%% Actually I'm going to try and write a new thing to make sure it
    %%% finds the first peak that's not noise?:

    idxs = find(vic_pip.PIP(signal_strt:end) < closed_threshold_volts); 
    if idxs(1) < signal_strt && signal_strt < idxs(end)
        pip_loc = signal_strt;
    else
        pip_loc = idxs(1);
        %%% not sure why I had it do this but I'll trust my old self. I
        %%% think this if statement should preserve the old functionality
        %%% while working for my current setup.
    end

    PIPCount = zeros(length(vic_pip.Count),1);
    PIPCount(pip_loc:end) = 1;

    vic_pip.PIPCount = PIPCount;
end