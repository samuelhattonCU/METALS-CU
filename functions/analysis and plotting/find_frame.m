function frameNum = find_frame(fd,target_disp)
    
    d = fd.Displacement;
    
    [r,c] = size(target_disp);
    frameNum = zeros(r,c);
    
    for i = 1:r
        for j = 1:c
            td = target_disp(i,j);
            idx = find(d>td,1,"first");
            
            if (td - d(idx-1)) < (d(idx) - td)
                idx = idx-1;
            end
            
            frameNum(i,j) = fd.Index(idx);
        end
    end

end