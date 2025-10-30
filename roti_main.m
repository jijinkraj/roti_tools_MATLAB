%% PUT ALL FILES IN SAME DIR
% sp3_interpolated_30s.xlsx
% *.TEC Files
% functions calcROTi, parseTEC file
%%
%SP3
sp3_file = 'sp3_interpolated_30s.xlsx';
T = readtable(sp3_file);
%% Folder with TEC files
folder_path = 'C:\Users\jijin\Desktop\JIF\test_ROTi';
files = dir(fullfile(folder_path, '*.17_TEC'));

% --- Preallocate output struct ---
results = struct();
results.ROTI = cell(numel(files),1);
results.IPP  = cell(numel(files),1);

ts = input('Enter start time (hhmmss): ');
te = input('Enter end time (hhmmss): ');
fl = dt2row(ts, te);
start_row = fl(1);
end_row = fl(2);

%% Process each file
for f_idx = 1:numel(files)
    filename = fullfile(folder_path, files(f_idx).name);
    fprintf('Processing file %d/%d: %s\n', f_idx, numel(files), files(f_idx).name);

    % --- 1. Parse TEC file ---
    [tec_file_data, receiver_xyz] = parseTECfile(filename,start_row,end_row);

    num_epochs = size(tec_file_data,1);

    % Ensure crop stays in bounds
    end_row_eff   = min(end_row, num_epochs);
    start_row_eff = max(1, start_row);

    % --- 2. Fill TEC into Nx32 array ---
    tec_array = NaN(end_row_eff-start_row_eff+1, 32, 'single');
    for epoch_idx = start_row_eff:end_row_eff
        prns = tec_file_data{epoch_idx,2};
        tec  = tec_file_data{epoch_idx,3};
        if ~isempty(prns) && ~isempty(tec)
            tec_array(epoch_idx-start_row_eff+1, prns) = tec;
        end
    end

    % --- 3. Compute ROTI ---
    ROTI_array = calcROTi(tec_array);

    % If calcROTi returned only NaNs (or empty), skip file
    if isempty(ROTI_array) || all(isnan(ROTI_array(:)))
        warning('Skipping file %s: no valid ROTI values.', files(f_idx).name);
        results.ROTI{f_idx} = NaN;   % mark skipped
        results.IPP{f_idx}  = NaN;
        continue;  % skip to next file
    end

    results.ROTI{f_idx} = ROTI_array;

    % --- 4. Compute IPP ---
    try
        ipp_data = calculateIPP_for_ROTI(ROTI_array, receiver_xyz, start_row_eff, end_row_eff,T);
        results.IPP{f_idx} = ipp_data;
    catch ME
        warning('IPP calculation failed for %s: %s', files(f_idx).name, ME.message);
        results.IPP{f_idx} = NaN;
    end
end

fprintf('Processing complete. %d files processed.\n', numel(files));
