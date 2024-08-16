function f = plot_col(data,var_name,remove_bads,xdat,ydat)
%{
% plot_col
% 
% CU Boulder METALS Project
% Comments updated: 16 August 2024
% Samuel Hatton
% 
% Inputs are identicle to get_plot_stuff.m inputs, for more information type
% 'help get_plot_stuff' into the command window.
% 
% Outputs
%     f   The plotted figure object.
% 
% Description:
%     This function is an alternative to 'compare_plot.m'. It creates a
%     single plot of whatever target variable is input to 'var_name'.
%     It is deprecated, in that it hasn't been updated in a long time, so
%     plots will not match those currently output by compare_plot (8/16/24).
%}
    
    % Check overload variables:
    if ~exist('ydat','var')
        ydat = 'Yp';
    end

    if ~exist('xdat','var')
        xdat = 'Xp';
    end

    if ~exist("remove_bads",'var')
        remove_bads = true;
    end

    % extract plot data structs:
    [l,r] = get_plot_stuff(data,var_name,remove_bads,xdat,ydat);

    % create figure, plot data
    f = figure;
    hold on
    contourf(l.xdat,l.ydat,l.cdat,LineWidth=0.2)
    contourf(r.xdat,r.ydat,r.cdat,LineWidth=0.2)
    cb = colorbar();
    ylabel(cb,var_name,FontSize=16,Rotation=270)
    xlabel(xdat)
    ylabel(ydat)
     
end
    