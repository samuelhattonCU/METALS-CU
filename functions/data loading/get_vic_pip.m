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
    signal_threshold_volts = 4.85;
    closed_threshold_volts = 0.15;
    signal_strt = find(vic_pip.PIP > signal_threshold_volts,1);
    if isempty(signal_strt)
        warning("No PIP signal found in '" + file_name + "', skipping")
        vic_pip = [];
        return
    end
    
    idxs = find(vic_pip.PIP(signal_strt:end) < closed_threshold_volts);

        %%% Note this doesn't look for more than the FIRST PIP but it
        %%% should avoid noise at the beggining of a test by waiting for
        %%% the signal to stabalize before starting to look for pips.
    pip_loc = idxs(1);
    PIPCount = zeros(length(vic_pip.Count),1);
    PIPCount(pip_loc:end) = 1;

    vic_pip.PIPCount = PIPCount;
end