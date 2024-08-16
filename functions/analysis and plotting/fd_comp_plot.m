function f = fd_comp_plot(fd1,fd2,spec_names,big_title,buffer,last_disp)
%{
fd_comp_plot.m

CU Boulder METALS Project
Comments updated: 16 August 2024

Inputs
    Mandatory
        fd1         A table or struct containing at least a 
                    '.Displacement' and '.Force' column. 
        fd2         A table or struct containing at least a 
                    '.Displacement' and '.Force' column. 
        spec_names  A 1x2 string containing labels for each sample; used in
                    force-displacement plot legend to differentiate the
                    curves.
        big_title   A string containing a title for the full figure, over
                    both subplots.
    Optional
        buffer      An integer number indicated at which index to begin
                    plotting the absolute and percent difference curves;
                    allows for large spikes early in the difference to be
                    ommitted from the plot. Default is 1, the 1st index.
        last_disp   A double indicating the displacement up-to-which the
                    absolute and percent difference curves will be plotted.
                    Useful if you are only interested in the first 5 mm,
                    for example, and don't want differences later in the
                    tests to affect the averages. Default is 15 mm.
Methodology:
    - Enforeces that 'fd1' is the shorter of the two data sets, if they are
      not the same length. fd1 is always plotted first in the left subplot,
      so sometimes legends can read confusingly. This may not need to be done
      anymore, and is likely a holdover from a previous mode of comparing the
      two force-displacement curves.
    - The maximum length of the absolute and percent difference plots is
      constrained by the length of the shorter of the two datasets.
    - Absolute difference is computed as abs(fd1.Force - fd2.compForce),
      where fd2.compForce is a "comparison" set of data, linearly interpreted
      at the displacement points corresponding to the data in fd1.Force. This
      is done to avoid comparing force values that are in the same index of
      the data column, but represent the force at slightly different
      displacements (or times).
    - Percent difference is calculated as the absolute difference divided by
      the absolute value of the average between the two curves at each point.
%}

    % Check overload variables
    if ~exist('buffer','var')
        buffer = 1;
    end

    if ~exist('last_disp','var')
        last_disp = 15;
    end

    % Make sure 'fd1' is the shorter of the two, if they're different lengths
    l1 = length(fd1.Displacement);
    l2 = length(fd2.Displacement);
    
    if l2 < l1
        temp1 = fd1;
        temp2 = fd2;
        fd1 = temp2;
        fd2 = temp1;
        temp1 = spec_names(1);
        temp2 = spec_names(2);
        spec_names(1) = temp2;
        spec_names(2) = temp1;
    end
    
    % Plot force-displacement curves
    
    f = figure;
    subplot(1,2,1)
    hold on
    
    plot(fd1.Displacement,fd1.Force,'blue')
    plot(fd2.Displacement,fd2.Force,'red')
    
    yline(0,'k')
    legend(spec_names,Location="best")
    xlabel("Displacement [mm]")
    ylabel("Force [N]")
    title("Force vs. Displacement")
    grid on
    box on
    ax = gca;
    ax.GridLineWidth = 1.5;
    
    subplot(1,2,2)
    
    cmap = colororder();
    

    % Get the number of points to be plotted
    l = length(fd1.Displacement(fd1.Displacement <= last_disp));
    
    % Do some weird stuff to handle plotting struct objects in addition to
    % table objects. Also, trims datasets to be identical lengths.
    if strcmp(class(fd1),'table')
        fd1 = fd1(1:l,:);
        fd2 = fd2(1:l,:);
    else
        fd2.Force = fd2.Force(1:l);
        fd2.Displacement = fd2.Displacement(1:l);
    end
    
    % Interpolate fd2 Force data to ensure identicle displacement locations
    fd2.compForce = interp1(fd2.Displacement,fd2.Force,fd1.Displacement);

    % Compute absolute and percent differences, and the averages of each.
    runmean = mean([fd1.Force,fd2.compForce],2);
    absDif = abs(fd1.Force - fd2.compForce);
    meanAbsDif = mean(absDif((buffer:end)),'omitnan');
    % percDif = 100 * absDif ./ abs(fd1.Force(1:l));
    percDif = 100 * absDif ./ abs(runmean);
    meanPercDif = mean(percDif(buffer:end),'omitnan');
    
    % Plot absolute difference
    yyaxis left
    plot(fd1.Displacement,absDif)
    yline(meanAbsDif,'--','LineWidth',1.2,'Color',cmap(1,:))
    ylabel("Absolute Difference [N]")
    
    % Plot percent difference
    yyaxis right
    plot(fd1.Displacement(buffer:end),percDif(buffer:end))
    yline(meanPercDif,'--','LineWidth',1.2,'Color',cmap(2,:))
    legend("Absolute Difference","Mean: " + string(round(meanAbsDif,2)) + " N", "Percent Difference","Mean: " + string(round(meanPercDif,2)) + "\%",Location="best")
    ylabel("Percent Difference")
    xlabel("Displacement [mm]")
    title("Absolute Difference Between Tests")
    grid("on")
    box on
    ax = gca;
    ax.GridLineWidth = 1.5;
    
    sgtitle(big_title)

end
