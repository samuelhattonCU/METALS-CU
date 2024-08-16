function [perc_er,perc_pts_ignored,perc_pts_hole,perc_additional_er] = calc_perc_missed(data)
% calc_perc_missed.m
%
% CU Boulder METALS Project
% 7 August 2024
% Samuel Hatton
% 
% 
% Inputs
%     data                A Matlab Table representation of a .csv file
%                         containing all the data export from VIC-3D for a
%                         single image frame.
% Outputs
%     perc_er             The percent of non-hole points dropped in the
%                         current frame.
%     perc_pts_ignored    This is the percent of points which do not cover
%                         holes that were bad (that is, not correlated) in
%                         the original frame.
%     perc_pts_hole       This is the percent of points in the data frame
%                         which represent a hole in the specimen.
%     perc_additional_er  This is the percent of good points dropped from the
%                         current frame; "good" meaning points which were
%                         identified and correlated in the orignial data
%                         frame.
% 
% Methodology
%     This script uses flags present in data.sigma to identify points which
%     were dropped in the reference data frame and which were dropped in the
%     currect data frame, and then uses connected component detection to
%     group the dropped points. It is assumed that there are four "holes" in
%     each set of frame data, and that they are the 4 largest clusters of
%     dropped points. These points receive a unique flag. The remaining
%     clusters are assumed to be missing data that doesn't correspond to a
%     hole, and are assigned a different flag. The occurences of each flag
%     are then counted and used to compute the output percentages.
    
    % separate data column into left and right side matrices
    [lmat,rmat] = col_to_mat(data,'sigma');
    
    %% left
    
    % Set all good data points to be zero
    lmat_tri = lmat;
    lmat_tri(lmat >= 0) = 0;
    
    % separate out "newly missing" points:
    newErMat = zeros(size(lmat_tri));
    newErMat(lmat_tri == -1) = -1;
    
    % zero out the new misses to get JUST the original blanks
    lmat_bi = lmat_tri;
    lmat_bi(lmat_tri == -1) = 0;
    
    % cluster remaining nonzero points
    lcc = bwconncomp(lmat_bi);
    lholesMat = zeros(size(lmat_bi));
    list_length = zeros(1,lcc.NumObjects);
    for i = 1:lcc.NumObjects
        list_length(i) = length(lcc.PixelIdxList{i});
    end
    
    [~,sort_idx] = sort(list_length); % smallest to largest
    hole_idx = lcc.PixelIdxList(sort_idx(end-3:end)); % the 4 largest
    for b = 1:length(hole_idx)
        % [i_clust,j_clust] = ind2sub(size(lholesMat),hole_idx{b});
        % lholesMat(i_clust,j_clust) = -3; % negative 3 indicates a cutout, not a missing point
        lholesMat(hole_idx{b}) = -3;
        % figure;imshow(label2rgb(labelmatrix(bwconncomp(lholesMat)),@hot,'c','shuffle'));
        % hold on;
        % scatter(j_clust,i_clust,10,'k','.')
    end
    
    lmissingMat = zeros(size(lmat_bi));
    missing_idx = lcc.PixelIdxList(sort_idx(1:end-4)); % all but the largest 4
    
    for b = 1:length(missing_idx)
        % [i_clust,j_clust] = ind2sub(size(lmissingMat),missing_idx{b});
        lmissingMat(missing_idx{b}) = -2; % negative 2 indicates a place that is not a cutout that was never included in a correlation, ei, there are not enough speckles, or something.
    end
    
    ogmat = lholesMat + lmissingMat + newErMat;
    u = unique(ogmat);
    if any(u == -5) || any(u == -4) % wouldn't catch is a -2 and -1 summed to -3
        error("Points added on top of eachother")
    end
    
    logsz = size(ogmat);
    lnpoints = logsz(1) * logsz(2);
    lnHolePts = nnz(lholesMat);
    lnogEr = nnz(lmissingMat);
    lnNewEr = nnz(newErMat);
    
    % perc_pts_hole = 100 * lnHolePts/lnpoints;
    % nNonHolePts = lnpoints - lnHolePts;
    % perc_pts_ignored = 100 * lnogEr/nNonHolePts; % percent of non-hole points dropped from the start
    % perc_additional_er = 100 * lnNewEr/ (nNonHolePts - lnogEr); % percent of originally used points dropped in current frame
    
    %% right
    
    % Set all good data points to be zero
    rmat_tri = rmat;
    rmat_tri(rmat >= 0) = 0;
    
    % separate out "newly missing" points:
    newErMat = zeros(size(rmat_tri));
    newErMat(rmat_tri == -1) = -1;
    
    % zero out the new misses to get JUST the original blanks
    rmat_bi = rmat_tri;
    rmat_bi(rmat_tri == -1) = 0;
    
    % cluster remaining nonzero points
    rcc = bwconncomp(rmat_bi);
    rholesMat = zeros(size(rmat_bi));
    list_length = zeros(1,rcc.NumObjects);
    for i = 1:rcc.NumObjects
        list_length(i) = length(rcc.PixelIdxList{i});
    end
    
    [~,sort_idx] = sort(list_length); % smallest to largest
    hole_idx = rcc.PixelIdxList(sort_idx(end-3:end)); % the 4 largest
    for b = 1:length(hole_idx)
        % [i_clust,j_clust] = ind2sub(size(lholesMat),hole_idx{b});
        % lholesMat(i_clust,j_clust) = -3; % negative 3 indicates a cutout, not a missing point
        rholesMat(hole_idx{b}) = -3;
        % figure;imshow(label2rgb(labelmatrix(bwconncomp(lholesMat)),@hot,'c','shuffle'));
        % hold on;
        % scatter(j_clust,i_clust,10,'k','.')
    end
    
    rmissingMat = zeros(size(rmat_bi));
    missing_idx = rcc.PixelIdxList(sort_idx(1:end-4)); % all but the largest 4
    
    for b = 1:length(missing_idx)
        % [i_clust,j_clust] = ind2sub(size(lmissingMat),missing_idx{b});
        rmissingMat(missing_idx{b}) = -2; % negative 2 indicates a place that is not a cutout that was never included in a correlation, ei, there are not enough speckles, or something.
    end
    
    ogmat = rholesMat + rmissingMat + newErMat;
    u = unique(ogmat);
    if any(u == -5) || any(u == -4) % wouldn't catch is a -2 and -1 summed to -3
        error("Points added on top of eachother")
    end
    
    rogsz = size(ogmat);
    rnpoints = rogsz(1) * rogsz(2);
    rnHolePts = nnz(lholesMat);
    rnogEr = nnz(lmissingMat);
    rnNewEr = nnz(newErMat);
    
    ogsz = logsz + rogsz;
    npoints = lnpoints + rnpoints;
    nHolePts = rnHolePts + lnHolePts;
    nogEr = lnogEr + rnogEr;
    nNewEr = lnNewEr + rnNewEr;
    
    
    perc_pts_hole = (100 * nHolePts/npoints);
    nNonHolePts = npoints - nHolePts;
    perc_pts_ignored = 100 * nogEr/nNonHolePts; % percent of non-hole points dropped from the start
    perc_additional_er = 100 * nNewEr/ (nNonHolePts - nogEr); % percent of originally used points dropped in current frame
    perc_er = 100 * (nNewEr + nogEr) / nNonHolePts; % percent of non-hole points dropped in the current frame.
end