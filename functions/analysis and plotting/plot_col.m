function f = plot_col(data,var_name,remove_bads,xdat,ydat)
    % if ~exist('comp_mult','var')
    %     comp_mult = 0;
    % end
    if ~exist('ydat','var')
        ydat = 'Yp';
    end

    if ~exist('xdat','var')
        xdat = 'Xp';
    end

    if ~exist("remove_bads",'var')
        remove_bads = true;
    end

    [l,r] = get_plot_stuff(data,var_name,remove_bads,xdat,ydat);

    f = figure;
    hold on
    contourf(l.xdat,l.ydat,l.cdat,LineWidth=0.2)
    contourf(r.xdat,r.ydat,r.cdat,LineWidth=0.2)
    cb = colorbar();
    ylabel(cb,var_name,FontSize=16,Rotation=270)
    xlabel(xdat)
    ylabel(ydat)
    
    
end
    