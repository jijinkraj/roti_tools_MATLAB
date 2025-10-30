function ROTI_matrix = calcROTi(tec_array, window_minutes, dt_sec)
    % tec_array : 2880x32 single, pre-filled TEC values aligned to PRN columns
    % window_minutes : ROTI window length (default 5)
    % dt_sec : sampling interval in seconds (optional, default 30)
    
    if nargin < 2 || isempty(window_minutes)
        window_minutes = 5;
    end
    if nargin < 3 || isempty(dt_sec)
        dt_sec = 30; 
    end

    [nEpochs, nPRN] = size(tec_array);

    % Handle empty or too short input
    if nEpochs < 2 || nPRN == 0
        ROTI_matrix = NaN(nEpochs, nPRN, 'single');
        return;
    end

    % Compute ROT (TECU/min)
    ROT_matrix = NaN(nEpochs, nPRN, 'single');
    ROT_matrix(2:end,:) = diff(tec_array) ./ (dt_sec / 60);

    % Spike detection: absolute threshold
    abs_thresh = 1.5; 
    ROT_matrix(abs(ROT_matrix) > abs_thresh) = NaN;

    % Spike detection: MAD per column
    for col = 1:nPRN
        rot_col = ROT_matrix(:,col);
        valid = ~isnan(rot_col);
        if any(valid)
            med_val = median(rot_col(valid));
            mad_val = mad(rot_col(valid),1);
            ROT_matrix(abs(rot_col - med_val) > 3*mad_val, col) = NaN;
        end
    end

    % Compute ROTI (rolling window std of ROT)
    window_samples = max(1, round(window_minutes * 60 / dt_sec));
    ROTI_matrix = NaN(nEpochs, nPRN, 'single');

    for col = 1:nPRN
        rot_col = ROT_matrix(:,col);
        for i = window_samples:nEpochs
            window_vals = rot_col(i-window_samples+1:i);
            non_nan_vals = window_vals(~isnan(window_vals));
            if numel(non_nan_vals) >= 9
                ROTI_matrix(i,col) = std(non_nan_vals);
            end
        end
    end
end
