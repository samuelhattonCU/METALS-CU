function idx_force_disp = sync_data(vic_pip,inst_data,ext_data,trim_tf,targ_var,targ_var_name)

    if ~exist("trim_tf","var") || isempty(trim_tf)
        trim_tf = true;
    end
    if ~exist("targ_var","var")
        targ_var = "ΔL";
    end
    if ~exist("targ_var_name","var")
        targ_var_name = 'Displacement';
    end
    
    if isa(targ_var_name,'string')
        targ_var_name = char(targ_var_name);
    end
    
    % fprintf("Syncing data")
    
    % check that vic and ext datas are the same length?
    if length(vic_pip.Count) > length(ext_data.Index)
        d = length(vic_pip.Count)-length(ext_data.Index);
        vic_pip = vic_pip(d+1:end,:);
    elseif length(vic_pip.Count) < length(ext_data.Index)
        d = length(ext_data.Index) - length(vic_pip.Count);
        ext_data = ext_data(d+1:end,:);
    end
    
    % Use the PIPCount from each data stream to identify the "match point"
    % between the two:
    inst_pip_loc = find(inst_data.PIPCount);
    vic_pip_loc = find(vic_pip.PIPCount);
    
    % get measured times at match point:
    inst_match_time = inst_data.Time(inst_pip_loc(1));
    vic_match_time = vic_pip.Time_0_1(vic_pip_loc(1));
    
    % adjust vic time to match inst time:
    time_diff = inst_match_time - vic_match_time;
    vic_pip.Time = vic_pip.Time_0_1 + time_diff;
    
    if trim_tf
        % identify vic data indeces with negative time:
        fake_time = vic_pip.Time < 0;
        
        % trim vic data:
        vic_pip(fake_time,:) = [];
        ext_data(fake_time,:) = [];
    
        % Use inst end time to trim away extra VIC data:
        inst_end_time = inst_data.Time(end);
        extra_time = vic_pip.Time > inst_end_time;
        vic_pip(extra_time,:) = [];
        ext_data(extra_time,:) = [];
    
        % zero out vic time:
        vic_pip.Time = vic_pip.Time - vic_pip.Time(1);
    
        % zero out displacement data
        ext_data.(targ_var) = ext_data.(targ_var) - ext_data.(targ_var)(1);
    end
    
    % create truncated instron data that matches 1to1 w/ ext. data
    
    zero_idx = find(vic_pip.Time >=0,1);
    
    idx = zeros(length(vic_pip.Count(zero_idx:end)),1);
    num_nans = 0;
    for i = 1:length(vic_pip.Count)
        % tf = round(inst_data.Time,1) == floor((vic_pip.Time(i))*10)/10;
        if vic_pip.Time(i) < 0
            num_nans = num_nans + 1;
        else
            tf = round(inst_data.Time,1) == round(vic_pip.Time(i),1);
            if sum(tf) == 0
                error("No Matching Time for time " + string(vic_pip.Time(i)))
            end
            locs = find(tf);
            idx(i - zero_idx + 1) = locs(1);
        end
    end
    
    buffer = nan(num_nans,1);
    buffer_time = vic_pip.Time(vic_pip.Time < 0);
    buffer_tab = table(buffer_time,buffer,buffer,buffer,'VariableNames',inst_data.Properties.VariableNames);
    
    % grab only relevant instron data
    inst_data = inst_data(idx,:);
    inst_data = [buffer_tab;inst_data];
    
    if ~(length(vic_pip.Time) == length(inst_data.Time))
        error("Data matching failed to create tables of equal length")
    end
    
    % combine into a new table
    idx_force_disp = table(ext_data.Index,ext_data.(targ_var),inst_data.Force,vic_pip.Time,'VariableNames',{'Index',targ_var_name,'Force','Time'});
    
    % % fill empty indexes? 
    % fst_idx = idx_force_disp.Index(1);
    % fill = zeros(fist_idx-1,1);
    % 
    % fill = table([1:fst_idx-1]',fill,fill,"VariableNames",{'Index','Displacement','Force'});
    % 
    % idx_force_disp = [fill;idx_force_disp];

end
