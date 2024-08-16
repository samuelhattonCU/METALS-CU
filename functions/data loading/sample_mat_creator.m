function sample_mat_creator()
    
    [selpath,spec_list] = sample_select;
    [data,specCount] = load_sample(selpath,spec_list,1);

    uisave({'data','specCount'},'sample');

end


