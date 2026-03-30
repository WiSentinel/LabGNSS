function [spoof] = ApplyGradualSpoof(gpsPvt, spoof)
    % Extracts N (number of epochs)
    N = size(gpsPvt.allLlaDegDegM, 1);
    
    % Initialize dynamic position array
    dynamic_pos = zeros(N, 3);
    
    start_epoch = spoof.t_start; 
    duration_epochs = spoof.t_duration;
    
    % Override duration if instant mode is selected
    if isfield(spoof, 'mode') && strcmp(spoof.mode, 'instant')
        duration_epochs = 0;
    end
    
    end_epoch = start_epoch + duration_epochs;
    
    % Find valid initial position (anchor point) in case of early NaNs
    idx_valid = find(~isnan(gpsPvt.allLlaDegDegM(:,1)) & ~isnan(gpsPvt.allLlaDegDegM(:,2)), 1);
    if isempty(idx_valid)
        error('No valid PVT solution found in log to use as initial position.');
    end
    
    % Try to get the position exactly at t_start, or fallback to the closest valid one
    if start_epoch <= N && ~isnan(gpsPvt.allLlaDegDegM(max(1, start_epoch), 1))
        pos_initial = gpsPvt.allLlaDegDegM(max(1, start_epoch), 1:3); 
    else
        pos_initial = gpsPvt.allLlaDegDegM(idx_valid, 1:3);
    end
    
    pos_target = spoof.target_position;
    
    for i = 1:N
        if i < start_epoch
            % Before attack: Keep true position
            if ~isnan(gpsPvt.allLlaDegDegM(i, 1))
                dynamic_pos(i, :) = gpsPvt.allLlaDegDegM(i, 1:3);
            else
                dynamic_pos(i, :) = pos_initial;
            end
        elseif i >= start_epoch && duration_epochs == 0
            % INSTANT ATTACK: Jump immediately to target
            dynamic_pos(i, :) = pos_target;
        elseif i >= start_epoch && i <= end_epoch
            % GRADUAL ATTACK: Linear interpolation
            progress = (i - start_epoch) / duration_epochs;
            dynamic_pos(i, :) = pos_initial + progress * (pos_target - pos_initial);
        else
            % After attack: Hold the target spoofed position
            dynamic_pos(i, :) = pos_target;
        end
    end
    
    % Overwrite the static spoof.position with the new dynamic Nx3 trajectory
    spoof.position = dynamic_pos;
end