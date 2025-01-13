function plot_area(d,f)
    % plot_area.m
    %
    % CU Boulder METALS Project
    % Comments updated: 01/13/2025
    % Samuel Hatton
    %
    %
    % Inputs
    %     d             Displacement data vector
    %     f             Force data vector
    % Outputs
    %     None          Creates figure showing area under curve per cycle
    % Methodology
    %     1. Identifies peaks in force data
    %     2. Calculates enclosed area for each cycle using polyarea
    %     3. Plots area vs cycle number
    % Dependencies
    %     findpeaks     MATLAB Signal Processing Toolbox
    %     polyarea      MATLAB Image Processing Toolbox

    % Identify regions:
    [peaks1,locs1] = findpeaks(f); %positive peaks
    [peaks2,locs2] = findpeaks(-f); %negative peaks
    locs = [locs1;locs2]; % combine location vectors
    [locs,order] = sort(locs); % put locations in order
    peaks = [peaks1;-peaks2]; % combine peaks vectors
    peaks = peaks(order); % sort peaks to match locs


    n = length(locs); % number of peaks
    l = length(1:2:n);
    area_vec = zeros(l,1);
    loop_id = 1:l;
    c = 1;
    for i = 1:2:n-2
        range = locs(i):locs(i+2);
        % lower_curve_range = locs(i):locs(i+1);
        % lower_area = trapz(d(lower_curve_range),f(lower_curve_range));
        % upper_curve_range = locs(i+1):locs(i+2);
        % upper_area = trapz(d(upper_curve_range),f(upper_curve_range));
        %
        % cycle_area = upper_area - lower_area;
        % area_vec(c) = cycle_area;
        cycle_area = polyarea(d(range),f(range));
        area_vec(c) = cycle_area;
        c = c+1;
    end

    figure
    plot(loop_id,area_vec)
    xlabel("Full Cycle")
    ylabel("Area Under Curve")
    grid on
    grid minor

end

