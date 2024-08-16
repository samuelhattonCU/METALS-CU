function compare_plot(data1,data2,var_name,sample_titles,var_label,bigtitle,data1er,data2er,data1oer,data2oer,nstd)
    if ~exist('nstd','var')
        nstd = 10;
    end

    if ~exist('data2oer','var')
        data2oer = false;
    end

    if ~exist('data1oer','var')
        data1oer = false;
    end

    if ~exist('data2er','var')
        data2er = false;
    end

    if ~exist('data1er','var')
        data1er = false;
    end

    if ~exist('bigtitle','var')
        bigtitle = "Specimen Comparison";
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

    % turn off text:
    data1er = false;
    data1oer = false;
    data2er = false;
    data2oer = false;

    [l1,r1] = get_plot_stuff(data1,var_name);
    [l2,r2] = get_plot_stuff(data2,var_name);
    % lmin = min(min(l1.cdat,[],"all"),min(l2.cdat,[],"all"));
    % lmax = max(max(l1.cdat,[],"all"),max(l2.cdat,[],"all"));
    % rmin = min(min(r1.cdat,[],"all"),min(r2.cdat,[],"all"));
    % rmax = max(max(r1.cdat,[],"all"),max(r2.cdat,[],"all"));
    % 
    % lims = [min(lmin,rmin),max(lmax,rmax)];
    
    sl1 = std(l1.cdat,'omitnan');
    sl2 = std(l2.cdat,'omitnan');
    sr1 = std(r1.cdat,'omitnan');
    sr2 = std(r2.cdat,'omitnan');
    a = mean([mean(l1.cdat,'omitnan'),mean(l2.cdat,'omitnan'),mean(r1.cdat,'omitnan'),mean(r2.cdat,'omitnan')]);
    s = max([sl1,sl2,sr1,sr2]);
    lims = [a-3*s,a+3*s];
    % lvls = linspace(lims(1),lims(2),15);

    % compute absolute difference
    labsdif = abs(l1.cdat - l2.cdat);
    
    % labstd = std(std(labsdif,'omitnan'),'omitnan');
    % labsdif(labsdif > 2*labstd) = NaN;

    rabsdif = abs(r1.cdat - r2.cdat);

    % rabstd = std(std(rabsdif,'omitnan'),'omitnan');
    % rabsdif(rabsdif > 2*rabstd) = NaN;

    figure
    
    % subplot(1,2,1)
    subplot(2,2,1)
    hold on
    contourf(l1.xdat,l1.ydat,l1.cdat,50,EdgeColor="none")
    contourf(r1.xdat,r1.ydat,r1.cdat,50,EdgeColor="none")
    cb = colorbar();
    % clim(lims)
    % ylabel(cb,var_label,FontSize=16,Rotation=270,Interpreter="latex")
    xlabel("Xp")
    ylabel("Yp")
    title(sample_titles(1))
    lim1 = clim();
        
    if data1oer && data1er
        txt1 = "Points originally skipped: " + round(data1oer,2) + "\%";
        txt2 = "Points dropped this frame: " + string(round(data1er,2)) + "\%";
        text(-15,-15,[txt1;txt2],"FontSize",14,"EdgeColor",'k','BackgroundColor',[1,1,1],Interpreter='latex')
    elseif data1oer
        txt = string(round(data1oer),2) + "% of points originally skipped.";
        text(-5,-17,txt,"FontSize",14,"EdgeColor",'k',Interpreter='latex')
    elseif data1er
        txt = string(round(data1er,2)) + "% of points dropped";
        text(-5,-17,txt,"FontSize",14,"EdgeColor",'k',Interpreter='latex')
    end

    % subplot(1,2,2)
    subplot(2,2,2)
    hold on
    contourf(l2.xdat,l2.ydat,l2.cdat,50,EdgeColor="none")
    contourf(r2.xdat,r2.ydat,r2.cdat,50,EdgeColor="none")
    cb = colorbar();
    % clim(lims)
    % ylabel(cb,var_label,FontSize=16,Rotation=270,Interpreter="latex")
    xlabel("Xp")
    ylabel("Yp")
    title(sample_titles(2))
    lim2 = clim();

    lims = [min(lim1(1),lim2(1)),max(lim1(2),lim2(2))];
    

    % if data2er
    %     txt = string(round(data2er,2)) + "\% of points dropped";
    %     text(-5,-17,txt,"FontSize",12,"EdgeColor",'k')
    % end   
    if data2oer && data2er
        txt1 = "Points originally skipped: " + round(data2oer,2) + "\%";
        txt2 = "Points dropped this frame: " + string(round(data2er,2)) + "\%";
        text(-15,-15,[txt1;txt2],"FontSize",14,"EdgeColor",'k','BackgroundColor',[1,1,1],Interpreter='latex')
    elseif data2oer
        txt = string(round(data2oer),2) + "% of points originally skipped.";
        text(-5,-17,txt,"FontSize",14,"EdgeColor",'k',Interpreter='latex')
    elseif data2er
        txt = string(round(data2er,2)) + "% of points dropped";
        text(-5,-17,txt,"FontSize",14,"EdgeColor",'k',Interpreter='latex')
    end

    subplot(2,2,1)
    clim(lims)
    subplot(2,2,2)
    clim(lims)
    colormap turbo

    % figure
    subplot(2,2,3)
    ax3 = gca;

    hold on

    lz = labsdif;
    rz = rabsdif;
    % lz(labsdif > 0.04) = NaN;
    % rz(rabsdif > 0.04) = NaN;

    mu = mean([mean(mean(lz,'omitnan'),'omitnan'),mean(mean(rz,'omitnan'),'omitnan')]);
    
    contourf(l1.xdat,l1.ydat,lz,50,EdgeColor="none")
    contourf(r1.xdat,r1.ydat,rz,50,EdgeColor="none")
    cb3 = colorbar();
    % ylabel(cb3,"$$|\Delta\varepsilon|$$",FontSize=16,Rotation=270,Interpreter="latex")
    xlabel("Xp")
    ylabel("Yp")
    title("Absolute Difference, $$|\Delta\varepsilon|$$, $$\overline{|\Delta\varepsilon|}$$ = " + string(round(mu,4)))
    
    lsz = size(labsdif);
    rsz = size(rabsdif);

    [lmax,lidx] = maxk(reshape(labsdif,[1,lsz(1)*lsz(2)]),5);
    [rmax,ridx] = maxk(reshape(rabsdif,[1,rsz(1)*rsz(2)]),5);
    
    lt5x = l1.xdat(lidx);
    lt5y = l1.ydat(lidx);
    rt5x = r1.xdat(ridx);
    rt5y = r1.ydat(ridx);
    biger = mean([lmax,rmax]);
    s1 = scatter(lt5x,lt5y,75,'red');
    scatter(rt5x,rt5y,75,'red')

    legend(s1, "Largest delta $$\approx$$ " + string(100*round(biger,2)) + "\%")
    % set(gca,'ColorScale','log')

    subplot(2,2,4)
    ax4 = gca;
    hold on

    % lz(labsdif > 0.02) = NaN;
    % rz(rabsdif > 0.02) = NaN;

    lstd = std(std(labsdif,'omitnan'),'omitnan');
    rstd = std(std(labsdif,'omitnan'),'omitnan');
    cutoff = nstd * max([lstd,rstd]);
    lz(labsdif > cutoff) = NaN;
    rz(rabsdif > cutoff) = NaN;

    contourf(l1.xdat,l1.ydat,lz,50,EdgeColor="none")
    contourf(r1.xdat,r1.ydat,rz,50,EdgeColor="none")
    cb4 = colorbar();
    % ylabel(cb4,"$$|\Delta\varepsilon|$$",FontSize=16,Rotation=270,Interpreter="latex")
    % tix = cb.Ticks;
    % tix = linspace(tix(1),tix(2),9);
    % cb.TickLabels = compose('%1.3f',tix);
    % cb4.Ticks = linspace(0,0.02,5);
    % cb4.TickLabels = compose('%1.3f',linspace(0,0.02,5));
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
    % cb3.Limits = cb4.Limits;

    % lsz = size(labsdif);
    % rsz = size(rabsdif);
    % 
    % [~,lidx] = maxk(reshape(labsdif,[1,lsz(1)*lsz(2)]),5);
    % [~,ridx] = maxk(reshape(rabsdif,[1,rsz(1)*rsz(2)]),5);
    
    % lt5x = l1.xdat(lidx);
    % lt5y = l1.ydat(lidx);
    % rt5x = r1.xdat(ridx);
    % rt5y = r1.ydat(ridx);
    % 
    % s1 = scatter(lt5x,lt5y,75,'red');
    % scatter(rt5x,rt5y,75,'red')
    % legend(s1, "Largest errors")

    colormap(ax3,"cool")
    colormap(ax4,"cool")
    
    sgtitle(bigtitle)
    % colormap cool
end