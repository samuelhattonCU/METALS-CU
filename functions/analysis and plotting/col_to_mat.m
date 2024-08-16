function [left_mat,right_mat] = col_to_mat(data,var_name)
% col_to_mat.m
%
% CU Boulder METALS Project
% Comments updated: 16 August 2024
% Samuel Hatton
% 
%
% Inputs
%     data          A Matlab Table representation of a .csv file containing 
%                   all the data export from VIC-3D for a single image 
%                   frame.
%     var_name      A character or string type containing the name of the
%                   target data column, which will be transformed into
%                   matrices and output. The name must match exactly one of
%                   the 'VariableNames' associated with the input 'data'
%                   table.
% Outputs
%     left_mat      A double type matrix containing the data in the
%                   'var_name' column of the 'data' table, transformed into
%                   a matrix according to the .x and .y columns of 'data'.
%                   The left data set is that corresponding to the left
%                   area of interest output from VIC-3D.
%     right_mat     A double type matrix containing the data in the
%                   'var_name' column of the 'data' table, transformed into
%                   a matrix according to the .x and .y columns of 'data'.
%                   The left data set is that corresponding to the right
%                   area of interest output from VIC-3D.
% 
% Methodology
%   This function assumes the input 'data' table contains all the data output
%   from VIC-3D, and that it is not separated into left and right sides or
%   anything else. It does require that the input 'data' table has a '.aoi'
%   column, containing numerical signifiers which indicate whether or not
%   the data contained in a given row is part of the left or right area of
%   interest.
% Depencies
%   get_lr_sz.m     uses data.x and data.y to determin the appropriate
%                   sizes of the transformed matrices.

    % Check input for correctness:
    if ~isa(var_name,'char')
        if isa(var_name,'string')
            var_name = char(var_name);
        else
            error("Input variable name is not valid. Input a char or string type variable.")
        end
    end
    
    % Determine column index of target variable:
    ls = data.Properties.VariableNames;
    for i = 1:length(ls)
        v = ls{i};
        if strcmp(v,var_name)
            targ_col = i;
            break
        end
    end

    % double check the target variable was found:
    if ~exist('targ_col','var')
        error("Target variable/column name not found in data table. Check that the input target variable exists in the input data table.")
    end
    
    % extract the target data according to area of interest (left & right)
    left_col = table2array(data(data.aoi == 3,targ_col));
    right_col = table2array(data(data.aoi == 4,targ_col));
    
    % get transformed matrix target sizes
    [left_sz, right_sz] = get_lr_sz(data);
    
    % double check that the number of points is identical in the matrix and
    % column representations of each dataset:
    if left_sz(1) * left_sz(2) ~= length(left_col)
        error("problem w/ left side sizing, check right as well")
    end
    if right_sz(1) * right_sz(2) ~= length(right_col)
        error("problem w/ right side sizing, but probably not the left side.")
    end

    % reshape the columns into matrices
    left_mat = reshape(left_col,left_sz);
    right_mat = reshape(right_col,right_sz);

end