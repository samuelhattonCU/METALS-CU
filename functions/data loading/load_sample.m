function [dataCell,specCount] = load_sample(selpath,specList,save_csv)
    % load_sample.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     selpath       Directory path containing specimen folders
    %     specList      (Optional) List of specimen folders to process
    %     save_csv      (Optional) Flag to save data as CSV (default = 0)
    % Outputs
    %     dataCell      Cell array containing processed data for each specimen
    %     specCount     Number of specimens processed
    % Methodology
    %     1. Navigates to specimen directories
    %     2. Loads VIC-3D, Instron, and extensometer data
    %     3. Interpolates over missing data points
    %     4. Organizes data into cell array structure
    % Dependencies
    %     get_vic_pip      Custom function
    %     get_inst_data    Custom function
    %     get_ext_data     Custom function

    if ~exist("save_csv",'var')
        save_csv = 0;
    end

    codeLoc = cd(selpath);

    if ~exist("specList",'var')
        specList = ls("Specimen*");
    end

    [specCount,~] = size(specList);

    dataCell = cell(specCount,5);

    for i = 1:specCount
        sampleRoot = cd(specList(i,:));
        cd(string(selpath) + "\" + string(specList(i,:)) + "\Data Export")

        vic_pip = get_vic_pip;
        inst_data = get_inst_data;
        ext_data = get_ext_data;

        % check for and interpolate over empty indexes
        tf = isnan(ext_data.("ΔL"));
        if sum(tf)
            bad = 1;
            dl = ext_data.("ΔL");
            nan_count = 0;
        else
            bad = 0;
        end

        while bad
            st_idx = find(tf,1);
            end_found = 0;
            for j = st_idx+1:length(tf)
                if ~tf(j)
                    end_idx = j-1;
                    break
                end
            end
            prec_val = dl(st_idx-1);
            fol_val = dl(end_idx+1);
            x = [st_idx-1, end_idx+1];
            v = [prec_val, fol_val];
            xq = st_idx:end_idx;
            vq = interp1(x,v,xq);
            dl(xq) = vq;
            tf = isnan(dl);
            nan_count = nan_count + length(xq);
            if ~sum(tf)
                bad = 0;
                ext_data.("ΔL") = dl;
            end
        end

        if ~isempty(vic_pip)
            idx_force_disp = sync_data(vic_pip,inst_data,ext_data);
        else
            idx_force_disp = inst_data;
        end

        % find specimen name
        spec_name = specList(i,:);

        if save_csv || exist("nan_count",'var')

            % find sample name
            idx = strfind(sampleRoot,'Sample');
            sample_name = sampleRoot(idx:end);
            sample_name_short = strrep(sample_name,"Sample ","sample");
            spec_name_short = strrep(spec_name,"Specimen ", "specimen");

            % create file name
            file_name = string(sample_name_short) + "_" + string(spec_name_short) + "_" + "force_disp.csv";

            if exist("nan_count",'var')
                warning("'load_sample.m' removed " + string(nan_count) + " NaNs from the displacement field for extensometer data file " + sample_name + ", " + spec_name)
            end

            if (save_csv && ~isempty(vic_pip) && ~isempty(inst_data))
                writetable(idx_force_disp,file_name);
            else
                display("Missing sync or instron data, no force-displacement data saved for " + sample_name + ", " + spec_name)
            end
        end

        frame_data_location = selpath + "\" + spec_name + "\" + "Data Export";

        dataCell{i,1} = vic_pip;
        dataCell{i,2} = inst_data;
        dataCell{i,3} = ext_data;
        dataCell{i,4} = idx_force_disp;
        dataCell{i,5} = spec_name;
        dataCell{i,6} = frame_data_location;
        cd(sampleRoot)
    end

    cd(codeLoc)
end
