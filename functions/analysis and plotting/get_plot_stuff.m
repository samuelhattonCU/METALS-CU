function [lstuff,rstuff] = get_plot_stuff(data,var_name,remove_bads,xdat,ydat)

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

    [l_cdat,r_cdat] =  col_to_mat(data,var_name);
    [l_xdat,r_xdat] = col_to_mat(data,xdat);
    [l_ydat,r_ydat] = col_to_mat(data,ydat);
    
    if remove_bads
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

    lstuff.xdat = l_xdat;
    lstuff.ydat = l_ydat;
    lstuff.cdat = l_cdat;

    rstuff.xdat = r_xdat;
    rstuff.ydat = r_ydat;
    rstuff.cdat = r_cdat;
end