function [peaks, locs, ratio] = strain_ratio_calc(strain,lambda)
% Inputs:
%       strain      vector containing strain values
%       lambda      approximate wave length of a cycle in units of integer
%                   indexes. You can estimate the wavelength by plotting
%                   just `plot(strain)' and then looking at the index
%                   distance between two subsequent peaks. 
%                   Default value: `50`
%                   Lambda is used to isolate major peaks from small,
%                   sub-cycle scale peaks (noise in the data)

    if ~exist('lambda','var')
        lambda = 50;
    end
    
    sd = smoothData(strain, 5);
    
    [~,locs] = findpeaks(sd);
    [~,nlocs] = findpeaks(-sd);
    
    locs = sort([locs; nlocs]);
    dlocs = [0;diff(locs)];
    
    mult = dlocs < 0.2 * lambda;
    locs(mult) = [];
    
    peaks = strain(locs);
    
    % find first min point in peaks
    
    if peaks(1) < peaks(2) % first point is a trough
        st = 1;
    else % first point is a peak
        st = 2;
    end
    
    l = length(peaks);
    if rem(l,2) == 0 % an even number of points
        ratio = zeros(l/2,1);
        n = l/2;
    else % odd number of points
        ratio = zeros((l-1)/2,1);
        n = (l-1)/2;
    end
    
    switch st
        case 1
            for i = 1:n
                ratio(i) = peaks(2*i-1) / peaks(2*i);
            end
        case 2
            for i = 1:n
                ratio(i) = peaks(2*i) / peaks(2*i - 1);
            end
    end

end


