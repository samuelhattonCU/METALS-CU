function midpoint = getHoles(filename)
    figure
    imdata = imread(filename);
    I = rgb2gray(imdata);
    
    Itf = I;
    sz = size(Itf);
    for i = 1:sz(1)*sz(2)
        if I(i) ~= 0
            Itf(i) = 0;
        else
            Itf(i) = 1;
        end
    end
    
    cc4 = bwconncomp(Itf,4);
    % sort by length to get the large cutout holes:
    list_length = zeros(1,cc4.NumObjects);
    for i = 1:cc4.NumObjects
        list_length(i) = length(cc4.PixelIdxList{i});
    end
    [~,sort_idx] = sort(list_length); % smallest to largest
    hole_idx = cc4.PixelIdxList(sort_idx); 
    
    imshow(label2rgb(labelmatrix(cc4),@copper,'c','shuffle'))
    
    meds = NaN(cc4.NumObjects,2);
    for i = 1:cc4.NumObjects
        [row,col] = ind2sub(sz,hole_idx{i});
        x = median(row);
        y = median(col);
        meds(i,1) = x;
        meds(i,2) = y;
    end
    
    
    
    holes = zeros(5,2);
    temp = meds;
    meds(:,1) = temp(:,2);
    meds(:,2) = temp(:,1);
    locs = zeros(5,1);
    for i = 1:5
        pt = drawpoint;
        holes(i,:) = pt.Position;
        k = dsearchn(meds,holes(i,:));
        locs(i) = k;
        pt.Label = "ROI " + string(k) + ", hole " + string(i);
        % pt.Label = "(" + holes(i,1) + "," + holes(i,2) + ")";
    end
    meds = meds(locs,:);
    
    % mid = mean(meds);
    midpoint = zeros(1,2);
    midpoint(1) = min(meds(:,1)) + 0.5 * (max(meds(:,1)) - min(meds(:,1)));
    midpoint(2) = min(meds(:,2)) + 0.5 * (max(meds(:,2)) - min(meds(:,2)));
    hold on
    scatter(meds(:,1),meds(:,2),50,'r','filled')
    scatter(midpoint(1),midpoint(2),50,'rx')

end