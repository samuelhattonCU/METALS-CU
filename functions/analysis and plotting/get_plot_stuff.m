function [lstuff,rstuff] = get_plot_stuff(data,var_name,remove_bads,xdat,ydat)
%{
% get_plot_stuff.m
% 
% CU Boulder METALS Project
% Comments updated: 16 August 2024
% Samuel Hatton
% 
% Inputs
%     Mandatory
%         data            A Matlab Table representation of a .csv file 
%                         containing all the data export from VIC-3D for a 
%                         single image frame.
%         var_name        A character or string type containing the name of 
%                         the target data column, which will be transformed 
%                         into matrices and output. The name must match 
%                         exactly one of the 'VariableNames' associated with 
%                         the input 'data' table.
%     Optional
%         remove_bads     boolean t/f, if true points with 'sigma' values
%                         less than zero are given the value NaN so they will
%                         show up as blank in the plots. These points
%                         correspond to all types of missing points (Holes,
%                         drops). Default is true.
%         xdat            String containing the VariableName of the data
%                         column intended to be used as the x-axis datapoint
%                         location. Default is 'Xp'.
%         ydat            String containing the VariableName of the data
%                         column intended to be used as the y-axis datapoint
%                         location. Default is 'Yp'.
% Outputs
%     lstuff              A struct containing '.xdat','.ydat', and
%                         .'cdat' fields. These are the inputs to a plotting
%                         function like contourf, containing data for the
%                         left side of the sample.
%     rstuff              A struct containing '.xdat','.ydat', and
%                         .'cdat' fields. These are the inputs to a plotting
%                         function like contourf, containing data for the
%                         right side of the sample.
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

    % Extract target variable data into matrices:
    [l_cdat,r_cdat] =  col_to_mat(data,var_name);
    % Extract x and y locations of target variable data into matrices:
    [l_xdat,r_xdat] = col_to_mat(data,xdat);
    [l_ydat,r_ydat] = col_to_mat(data,ydat);
    
    % Set non-physical points to have a value of NaN
    if remove_bads
        % Extract point error values:
        [l_sigma,r_sigma] = col_to_mat(data,'sigma');
        [r,c] = size(l_sigma);
        for i = 1:r
            for j = 1:c
                if l_sigma(i,j) < 0
                    l_cdat(i,j) = NaN;
                end
            end
        end
        [r,c] = size(r_sigma);
        for i = 1:r
            for j = 1:c
                if r_sigma(i,j) < 0
                    r_cdat(i,j) = NaN;
                end
            end
        end
    else
        disp("goof")
    end

    % save data into output structs:
    lstuff.xdat = l_xdat;
    lstuff.ydat = l_ydat;
    lstuff.cdat = l_cdat;

    rstuff.xdat = r_xdat;
    rstuff.ydat = r_ydat;
    rstuff.cdat = r_cdat;
end