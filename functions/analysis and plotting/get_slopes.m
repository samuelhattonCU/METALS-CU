function [s1,s2] = get_slopes(d,f)
    % get_slopes.m
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
    %     s1            Initial slope (stiffness) from linear fit of first region
    %     s2            Secondary slope from linear fit of second region
    % Methodology
    %     1. Identifies peak regions in force data
    %     2. Fits linear curve to initial region (d < 0.15)
    %     3. Finds second region between peaks 2 and 3
    %     4. Uses ischange() to identify slope changes in second region
    %     5. Returns slopes from both linear fits
    % Dependencies
    %     findpeaks     MATLAB Signal Processing Toolbox
    %     ischange      MATLAB Signal Processing Toolbox
    %     polyfit       MATLAB Curve Fitting Toolbox


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
    x1 = [d0(1),d0(end)];
    y1 = polyval(p1,x1);
    s1 = p1(1);


    % second region
    f2 = f(locs(2):locs(3));
    d2 = d(locs(2):locs(3));

    tf = ischange(f2); % find changes in force slope
    pts = find(tf,2); % assumes we want the slope of the second section of f2
    p2 = polyfit(d2(pts),f2(pts),1);
    x2 = d2(pts);
    y2 = polyval(p2,x2);
    s2 = p2(1);

    figure
    plot(d(1:locs(3)),f(1:locs(3)))
    hold on
    plot(x1,y1,'x--')
    plot(x2,y2,'x--')
    legend("Data","First Slope S1 = " + string(s1), "Second Slope S2 = " + string(s2))
    xlabel("Displacement [mm]")
    ylabel("Force [N]")
    grid on
    grid minor



end
