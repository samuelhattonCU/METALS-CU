function plot_slope_time(d,f)
    % plot_slope_time.m
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
    %     None          Creates figure showing slope evolution over time/cycles
    % Methodology
    %     1. Identifies peaks in force data
    %     2. Calculates initial slope from first loading region
    %     3. Finds slopes in subsequent loading cycles
    %     4. Plots slope vs cycle number
    % Dependencies
    %     findpeaks     MATLAB Signal Processing Toolbox
    %     ischange      MATLAB Signal Processing Toolbox

     % Identify regions:
    [peaks1,locs1] = findpeaks(f); %positive peaks
    [peaks2,locs2] = findpeaks(-f); %negative peaks
    locs = [locs1;locs2]; % combine location vectors
    [locs,order] = sort(locs); % put locations in order
    peaks = [peaks1;-peaks2]; % combine peaks vectors
    peaks = peaks(order); % sort peaks to match locs


    % the first region:
    f0 = f(1:locs(1));
    d0 = d(1:locs(1));

    inrange = d0 < 0.15;

    f0 = f0(inrange);
    d0 = d0(inrange);
    p1 = polyfit(d0,f0,1);
    s1 = p1(1);


    % each subsequent region:
    n = length(locs);
    l = length(1:2:n);
    slope_vec = zeros(l,1);
    slope_vec(1) = s1;
    loop_id = 1:l;
    c = 2;
    for i = 2:2:n-1
        range = locs(i):locs(i+1);
        fi = f(range);
        di = d(range);
        li = length(di);
        ei = floor(li/2);
        % tf = ischange(fi);
        % pts = find(tf,2);
        % if isscalar(pts)
        %     pts = [1,pts];
        % end
        % pi = polyfit(di(pts),fi(pts),1);
        % pi = polyfit(di(1:ei),fi(1:ei),1);
        pi = polyfit(di,fi,1);
        si = pi(1);
        slope_vec(c) = si;
        c = c+1;
    end
    figure
    plot(loop_id,slope_vec);
    xlabel("Cycles")
    ylabel("Slope")
end

