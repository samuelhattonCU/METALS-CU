function f = fd_comp_plot(fd1,fd2,spec_names,bigTitle,buffer,last_disp)
    
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
    
    l = length(fd1.Displacement(fd1.Displacement <= last_disp));
    if strcmp(class(fd1),'table')
        fd1 = fd1(1:l,:);
        fd2 = fd2(1:l,:);
    else
        fd2.Force = fd2.Force(1:l);
        fd2.Displacement = fd2.Displacement(1:l);
    end
    
    fd2.compForce = interp1(fd2.Displacement,fd2.Force,fd1.Displacement);

    
    runmean = mean([fd1.Force,fd2.compForce],2);
    absDif = abs(fd1.Force - fd2.compForce);
    meanAbsDif = mean(absDif((buffer:end)),'omitnan');
    % percDif = 100 * absDif ./ abs(fd1.Force(1:l));
    percDif = 100 * absDif ./ abs(runmean);
    meanPercDif = mean(percDif(buffer:end),'omitnan');
    
    yyaxis left
    plot(fd1.Displacement,absDif)
    yline(meanAbsDif,'--','LineWidth',1.2,'Color',cmap(1,:))
    ylabel("Absolute Difference [N]")
    
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
    
    sgtitle(bigTitle)

end
