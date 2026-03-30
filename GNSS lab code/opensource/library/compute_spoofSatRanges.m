function [spoof] = compute_spoofSatRanges(gnssMeas,gpsPvt,spoof)
% ... (Keep your original header comments here) ...

% init
N = length(gpsPvt.svPos);
spSv_ranges = cell(1,N);
spSv_ranges_diff = cell(1,N);
spSv_ranges_diff_zeros = cell(1,N);
M = length(gnssMeas.Svid);

% convert spoof pos form LLA to ECEF
% spoof.position is now an Nx3 matrix, Lla2Xyz will return an Nx3 ECEF matrix
spPos_all = Lla2Xyz(spoof.position); 

% extract SV pos and compute ranges for each time
for i = 1:N
    
    % avoid breaking if first set of svPos is empty
    if size(gpsPvt.svPos{i},1)==0 || size(gpsPvt.svPos{i},2)==0
        continue;
    end
    
    spSv_ranges_diff_zeros{i} = zeros(M,1);
    % extract SV pos 
    svPos = gpsPvt.svPos{i}(:,2:4);
    svPosId = gpsPvt.svPos{i}(:,1);
    pvtRanges = gpsPvt.svPos{i}(:,6);

    % Extract the specific spoofed ECEF position for the current epoch i
    if size(spPos_all, 1) >= i
        spPos = spPos_all(i, :);
    else
        spPos = spPos_all(end, :); % Fallback
    end

    % compute ranges as geometrical norms
    spSv_ranges{i} = vecnorm((svPos - spPos)'); 

    for j=1:M
        k = find(svPosId==gnssMeas.Svid(j),1);
        if ~isempty(k)
            spSv_ranges_diff{i}(k) = spSv_ranges{i}(k)-gnssMeas.PrM(i,j); % consistent with gpsPvt sat indexing
            spSv_ranges_diff_zeros{i}(j) = spSv_ranges{i}(k)-gnssMeas.PrM(i,j); % consistent with gnssMeas sat indexing
            spSv_ranges_diff_zeros{i}(j) = spSv_ranges{i}(k)-pvtRanges(k);
        end
    end

end

spoof.spSv_ranges = spSv_ranges;
spoof.spSv_ranges_diff = spSv_ranges_diff;
spoof.spSv_ranges_diff_zeros = spSv_ranges_diff_zeros;
end