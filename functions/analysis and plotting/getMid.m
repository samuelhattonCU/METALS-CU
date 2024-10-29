function midpoint = getMid(data)

    f = figure;
    contourf(data.uplt.xdat,data.uplt.ydat,data.uplt.cdat)
    title("Click the 4 corners of the middle area")
    
    corners = zeros(4,2);
    for i = 1:4
        pt = drawpoint;
        corners(i,:) = pt.Position;
    end
    close(f);

    mpx = mean(corners(:,1));
    mpy = mean(corners(:,2));
    midpoint = [mpx,mpy];

end