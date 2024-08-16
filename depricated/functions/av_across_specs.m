function [disp_av,force_av] = av_across_specs(data,range)

    numSpecs = length(range);
    
    subdata = data(range,:);
    
    l = zeros(numSpecs,1);
    
    for i = 1:numSpecs
        fd = subdata{i,4};
        l(i) = length(fd.Index);
    end
    lm = min(l);
    disp_sum = zeros(lm,1);
    force_sum = zeros(lm,1);
    for i = 1:numSpecs
        fd = subdata{i,4};
        disp_sum = disp_sum + fd.Displacement(1:lm);
        force_sum = force_sum + fd.Force(1:lm);
    end
    
    disp_av = disp_sum / numSpecs;
    force_av = force_sum / numSpecs;

end