function compare_plot(data1,data2,var_name,sample_titles,var_label,big_title,data1_er,data2_er,data1_oer,data2_oer,nstd)
% compare_plot.m
% 
% CU Boulder METALS Project
% Comments updated: 16 August 2024
% Samuel Hatton
% 
% Inputs
%     Mandatory
%         data1           A Matlab Table representation of a .csv file 
%                         containing all the data export from VIC-3D for 
%                         a single image frame. This dataset will be plotted
%                         first, in the (2,2,1) subplot.
%         data2           A Matlab Table representation of a .csv file 
%                         containing all the data export from VIC-3D for 
%                         a single image frame. This dataset will be plotted
%                         second, in the (2,2,2) subplot.
%     Optional
%         var_name        A character array containing the name of the data
%                         column to be compared and plotted between samples.
%                         Default is 'eyy'.
%         sample_titles   A 1x2 string containing titles for the (2,2,1) and
%                         (2,2,2) subplots in the 4x4 plot grid. Latex
%                         interpreted. Default value is 
%                         ["1st Sample","2nd Sample"].
%         var_label       A string containing a label for the colorbars on
%                         the subplots. Generally should
%                         match 'var_name'. Should be written for a latex
%                         interpreter. Default is "Data".
%                         CURRENTLY COMMENTED OUT: labeling the
%                         colorbars takes an astonishing amount of time, so
%                         the labels are commented out below and this input
%                         isn't currently used.
%         big_title       A string containing text to be displayed as the
%                         title of the figure window. Latex interpreted.
%                         Default is "Specimen Comparison".
%         data1_er        A double containing the total percent of points in 
%                         the data1 dataset that are missing due to being
%                         dropped by VIC-3D during correlation.
%         data2_er        A double containing the total percent of points in 
%                         the data2 dataset that are missing due to being
%                         dropped by VIC-3D during correlation.
%         data1_oer       A double containing the percent of points which
%                         were dropped in the reference image for the data1
%                         dataset. This original value can be compared with
%                         the total value for the frame to understand how
%                         many points are newly dropped.
%         data2_oer       A double containing the percent of points which
%                         were dropped in the reference image for the data2
%                         dataset. This original value can be compared with
%                         the total value for the frame to understand how
%                         many points are newly dropped.
%         nstd            Number of standard deviates from the sample mean to
%                         'keep' when plotting the (2,2,4) subplot, and
%                         determing the colorbar limits for both that and the
%                         (2,2,3) subplots. This is inteneded to make a
%                         colorbar distribution that is more readable,
%                         eliminating really far away outlier data points.
%                         Default is 10.
% Methodology
%     Does some basic math to determin limits for colorbars, and plots both
%     datasets. Uses get_plot_stuff.mat to get matrix representations of the
%     input datasets. Directly subtracts datasets from eachother for the 3rd
%     and 4th subplots, meaning they need to be exactly the same size (in
%     terms of data points and x/y arrangements of those data points). This
%     requires (I suspect) that the datasets come from VIC-3D projects that
%     use identically sized areas of interest.
% Dependencies:
%     get_plot_stuff
%         -> col_to_mat.m
%             -> get_lr.sz.m

    % Check overload variables and set defaults for missing ones:
    if ~exist('nstd','var')
        nstd = 10;
    end

    if ~exist('data2oer','var')
        data2_oer = false;
    end

    if ~exist('data1oer','var')
        data1_oer = false;
    end

    if ~exist('data2er','var')
        data2_er = false;
    end

    if ~exist('data1er','var')
        data1_er = false;
    end

    if ~exist('bigtitle','var')
        big_title = "Specimen Comparison";
    end
    
    if ~exist('sample_titles','var')
        sample_titles = ["1st Sample","2nd Sample"];
    end
    
    if ~exist('var_label','var')
        var_label = "Data";
    end
    
    if ~exist('var_name','var')
        var_name = 'eyy';
    end

    %%%%%%%% The error percent text displays cause weird problems with the
    %%%%%%%% colorbar label interpreter? Figure objects are a bit of a
    %%%%%%%% mess. I've hardcoded false here to avoid errors/warnings, but
    %%%%%%%% if you input both er and oer values, and remove the
    %%%%%%%% hardcoding, then the code will probably run without error.
    %%%%%%%% It's mostly when either just er or oer values are provided
    %%%%%%%% that it throws a fit.
    % turn off text:
    data1_er = false;
    data1_oer = false;
    data2_er = false;
    data2_oer = false;
    %%%%%%%%
    %%%%%%%%

    % extract structs containing left and right points from both datasets:
    [l1,r1] = get_plot_stuff(data1,var_name);
    [l2,r2] = get_plot_stuff(data2,var_name);


    % compute absolute difference between the two sets of data
    % Will break if they're not the same size
    labsdif = abs(l1.cdat - l2.cdat);
    rabsdif = abs(r1.cdat - r2.cdat);

    % Plotting:
    figure
    
    % Plot data1
    subplot(2,2,1)
    hold on
    contourf(l1.xdat,l1.ydat,l1.cdat,50,EdgeColor="none")
    contourf(r1.xdat,r1.ydat,r1.cdat,50,EdgeColor="none")
    cb = colorbar();
    % COMMENTED OUT FOR PERFORMANCE:
    % ylabel(cb,var_label,FontSize=16,Rotation=270,Interpreter="latex")
    xlabel("Xp")
    ylabel("Yp")
    title(sample_titles(1))
    lim1 = clim();
    
    % add text box with frame error information
    if data1_oer && data1_er
        txt1 = "Points originally skipped: " + round(data1_oer,2) + "\%";
        txt2 = "Points dropped this frame: " + string(round(data1_er,2)) + "\%";
        text(-15,-15,[txt1;txt2],"FontSize",14,"EdgeColor",'k','BackgroundColor',[1,1,1],Interpreter='latex')
    elseif data1_oer
        txt = string(round(data1_oer),2) + "% of points originally skipped.";
        text(-5,-17,txt,"FontSize",14,"EdgeColor",'k',Interpreter='latex')
    elseif data1_er
        txt = string(round(data1_er,2)) + "% of points dropped";
        text(-5,-17,txt,"FontSize",14,"EdgeColor",'k',Interpreter='latex')
    end

    % Plot data2
    subplot(2,2,2)
    hold on
    contourf(l2.xdat,l2.ydat,l2.cdat,50,EdgeColor="none")
    contourf(r2.xdat,r2.ydat,r2.cdat,50,EdgeColor="none")
    cb = colorbar();
    % COMMENTED OUT FOR PERFORMANCE:
    % ylabel(cb,var_label,FontSize=16,Rotation=270,Interpreter="latex")
    xlabel("Xp")
    ylabel("Yp")
    title(sample_titles(2))
    lim2 = clim();

    % compare default colorbar limits from data1 and data2 plots to get
    % limits that fit both
    lims = [min(lim1(1),lim2(1)),max(lim1(2),lim2(2))];
    
    % add text box with frame error information
    if data2_oer && data2_er
        txt1 = "Points originally skipped: " + round(data2_oer,2) + "\%";
        txt2 = "Points dropped this frame: " + string(round(data2_er,2)) + "\%";
        text(-15,-15,[txt1;txt2],"FontSize",14,"EdgeColor",'k','BackgroundColor',[1,1,1],Interpreter='latex')
    elseif data2_oer
        txt = string(round(data2_oer),2) + "% of points originally skipped.";
        text(-5,-17,txt,"FontSize",14,"EdgeColor",'k',Interpreter='latex')
    elseif data2_er
        txt = string(round(data2_er,2)) + "% of points dropped";
        text(-5,-17,txt,"FontSize",14,"EdgeColor",'k',Interpreter='latex')
    end

    % Go back and enforce matching colorbar limits in both subplots
    subplot(2,2,1)
    clim(lims)
    subplot(2,2,2)
    clim(lims)
    colormap turbo

    % Plot absolute differences, with outliers
    subplot(2,2,3)
    ax3 = gca;
    hold on
    
    % compute the average absolute difference across the full frame
    mu = mean([mean(mean(labsdif,'omitnan'),'omitnan'),mean(mean(rabsdif,'omitnan'),'omitnan')]);
    
    contourf(l1.xdat,l1.ydat,labsdif,50,EdgeColor="none")
    contourf(r1.xdat,r1.ydat,rabsdif,50,EdgeColor="none")
    cb3 = colorbar();
    % COMMENTED OUT FOR PERFORMANCE:
    % ylabel(cb3,"$$|\Delta\varepsilon|$$",FontSize=16,Rotation=270,Interpreter="latex")
    xlabel("Xp")
    ylabel("Yp")
    title("Absolute Difference, $$|\Delta\varepsilon|$$, $$\overline{|\Delta\varepsilon|}$$ = " + string(round(mu,4)))
    
    % get data sizes to reshape data in order to use maxk function
    lsz = size(labsdif);
    rsz = size(rabsdif);

    % extract the 5 largest outliers from each side:
    [lmax,lidx] = maxk(reshape(labsdif,[1,lsz(1)*lsz(2)]),5);
    [rmax,ridx] = maxk(reshape(rabsdif,[1,rsz(1)*rsz(2)]),5);
    
    % mark the outliers on the plot
    lt5x = l1.xdat(lidx);
    lt5y = l1.ydat(lidx);
    rt5x = r1.xdat(ridx);
    rt5y = r1.ydat(ridx);
    biger = mean([lmax,rmax]);
    s1 = scatter(lt5x,lt5y,75,'red');
    scatter(rt5x,rt5y,75,'red')

    legend(s1, "Largest delta $$\approx$$ " + string(100*round(biger,2)) + "\%")
    % set(gca,'ColorScale','log')

    % Plot absolute difference without outliers
    subplot(2,2,4)
    ax4 = gca;
    hold on
    
    % create duplicates to preserve original data with outliers:
    lz = labsdif;
    rz = rabsdif;

    % compute standard deviations and remove outliers outside of nstd
    lstd = std(std(labsdif,'omitnan'),'omitnan');
    rstd = std(std(labsdif,'omitnan'),'omitnan');
    cutoff = nstd * max([lstd,rstd]);
    lz(labsdif > cutoff) = NaN;
    rz(rabsdif > cutoff) = NaN;

    contourf(l1.xdat,l1.ydat,lz,50,EdgeColor="none")
    contourf(r1.xdat,r1.ydat,rz,50,EdgeColor="none")
    cb4 = colorbar();
    % COMMENTED OUT FOR PERFORMANCE:
    % ylabel(cb4,"$$|\Delta\varepsilon|$$",FontSize=16,Rotation=270,Interpreter="latex")
    cb4.Limits = [0,cutoff];
    xlabel("Xp")
    ylabel("Yp")
    mu = mean([mean(mean(lz,'omitnan'),'omitnan'),mean(mean(rz,'omitnan'),'omitnan')]);
    title("$$|\Delta\varepsilon|$$, Outliers Removed, $$\overline{|\Delta\varepsilon|}$$ = " + string(round(mu,4)));
    lims = clim();
    subplot(2,2,3)
    clim(lims)
    cb3.Ruler.Exponent = 0;
    cb4.Ruler.Exponent = 0;

    colormap(ax3,"cool")
    colormap(ax4,"cool")
    
    % Add figure title
    sgtitle(big_title)
end