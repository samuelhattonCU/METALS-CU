function prePIP_loading()

    [selpath,spec_list] = sample_select;
    
    [specCount,~] = size(spec_list);
    for i = 1:specCount
        back = cd(selpath + "\" + spec_list(i,:) + "\Data Export");
        
        extData = get_ext_data;
        instData = get_inst_data;
        cd(back)
        uisave({'instData'},spec_list(i,:));
    end
    
    %%
    
    % % find frame index where sample starts moving
    % start_frame_number = extData.Index(find(table2array(extData(:,3)) > 0.01,1,'first'));
    % 
    % % trim extData
    % extData = extData(extData.Index >= start_frame_number,:);
end