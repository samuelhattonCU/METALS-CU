function [dout,er] = compress(din,mult)
    
    if any(any(isnan(din)))
        nanr = [];
        nanc = [];
        [r,c] = size(din);
        for i = 1:r
            for j = 1:c
                if isnan(din(i,j))
                    din(i,j) = 0;
                    nanr = [nanr,i];
                    nanc = [nanc,j];
                end
            end
        end
    end

    [U,S,V] = svd(din);
    
    l = length(diag(S));
    n = floor(l/mult);
    
    C = S;
    C(n+1:end,:) = 0;
    C(:,n+1:end) = 0;
    
    dout = U*C*V';
    er = sum(sum((din-dout).^2));
    % if exist('nanr','var')
    %     for i = 1:length(nanr)
    %         for j = 1:length(nanc)
    %             dout(nanr(i),nanc(j)) = NaN;
    %         end
    %     end
    % end
end


