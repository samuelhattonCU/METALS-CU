function [data,perc_additional_er,perc_pts_ignored,cleaned_frame] = frame_cleaner(data,single)
    % frame_cleaner.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     data          Structure containing DIC data (X, Y, sigma fields)
    %     single        (Optional) Boolean flag for single AOI processing
    % Outputs
    %     data          Cleaned data structure with flagged duplicates
    %     perc_additional_er    Percentage of additional error points
    %     perc_pts_ignored      Percentage of points ignored
    %     cleaned_frame         Final cleaned frame data
    % Methodology
    %     1. Identifies points with invalid sigma values (-1)
    %     2. Detects and flags duplicate X coordinates
    %     3. Processes AOIs if multiple regions present
    %     4. Updates sigma values to mark problematic points
    % Dependencies
    %     None

    if ~exist("single","var")
        single = false;
    end

    bad = data.sigma == -1; % all the points with a sigma value of -1

    [gc, gr] = groupcounts(data.X(bad)); % unique groups of X vals w/ sigma value of -1

    trash_X = gr(max(gc) == gc); % X value assigned to all the duplicates

    trash_log = data.X == trash_X; % logical index in data file of all the duplicates

    % data = data(~trash_log,:); % remove rows containing duplicates
    data.sigma(trash_log) = -2; % flag "dup" rows w/ -2 instead of -1

    % n_drops = sum(data.sigma == -1); % count number of "dropped" points (not just empty space, but misses)

    % percent_dropped = 100 * n_drops/length(data.sigma); % percent of the sample dropped within AOIs

    if ~single
        % find aoi ids?
        aoi_jump_idx = find(abs(diff(data.y)) > 10);

        order = zeros(4,1);
        binSizes = [aoi_jump_idx(1),aoi_jump_idx(2) - aoi_jump_idx(1), aoi_jump_idx(3) - aoi_jump_idx(2), length(data.y) - aoi_jump_idx(3)];
        % [~,i] = sort(binSizes);
        % order(i(1:2)) = [1,2];

        aoi = zeros(length(data.x),1);
        num_aois = length(aoi_jump_idx) + 1;

        if binSizes(1) < binSizes(3) % implies small tiny aois 1st
            aoi(1:aoi_jump_idx(1)) = 1;
            aoi(aoi_jump_idx(1)+1:aoi_jump_idx(2)) = 2;
            if data.x(aoi_jump_idx(2)+10) < data.x(aoi_jump_idx(3)+10) % implies "left" is first
                aoi(aoi_jump_idx(2)+1:aoi_jump_idx(3)) = 3;
                aoi(aoi_jump_idx(3)+1:end) = 4;
            else
                aoi(aoi_jump_idx(2)+1:aoi_jump_idx(3)) = 4;
                aoi(aoi_jump_idx(3)+1:end) = 3;
            end
        elseif binSizes(1) > binSizes(3) % implies big aois 1st
            aoi(aoi_jump_idx(2)+1:aoi_jump_idx(3)) = 1;
            aoi(aoi_jump_idx(3)+1:end) = 2;
            if data.x(10) < data.x(aoi_jump_idx(1) + 10) % implies "left" is first
                aoi(1:aoi_jump_idx(1)) = 3;
                aoi(aoi_jump_idx(1)+1:aoi_jump_idx(2)) = 4;
            else
                aoi(1:aoi_jump_idx(1)) = 4;
                aoi(aoi_jump_idx(1)+1:aoi_jump_idx(2)) = 3;
            end
        end
        data.aoi = aoi;

        [perc_additional_er,perc_pts_ignored] = calc_perc_missed(data);
    end

    cleaned_frame = data(~trash_log,:); % remove rows containing duplicates
    % cleaned_frame = data(data.sigma ~= -1,:); % removes "dropped" points as well
    cleaned_frame = cleaned_frame(cleaned_frame.sigma ~= -1,:); % removes "dropped" points as well

end
