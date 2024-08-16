function [left_mat,right_mat] = col_to_mat(data,var_name)

    if ~isa(var_name,'char')
        if isa(var_name,'string')
            var_name = char(var_name);
        else
            error("Input variable name is not valid. Input a char or string type variable.")
        end
    end
    
    ls = data.Properties.VariableNames;
    for i = 1:length(ls)
        v = ls{i};
        if strcmp(v,var_name)
            targ_col = i;
            break
        end
    end
    
    if ~exist('targ_col','var')
        error("Target variable/column name not found in data table. Check that the input target variable exists in the input data table.")
    end
    
    left_col = table2array(data(data.aoi == 3,targ_col));
    right_col = table2array(data(data.aoi == 4,targ_col));
    
    [left_sz, right_sz] = get_lr_sz(data);
    
    if left_sz(1) * left_sz(2) ~= length(left_col)
        error("problem w/ left side sizing, check right as well")
    end
    if right_sz(1) * right_sz(2) ~= length(right_col)
        error("problem w/ right side sizing, but probably not the left side.")
    end

    left_mat = reshape(left_col,left_sz);
    right_mat = reshape(right_col,right_sz);

end