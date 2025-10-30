function ipp_data = calculateIPP_for_ROTI(ROTI_array, receiver_xyz, start_epoch, end_epoch,T)
% Compute IPP lat/lon from ROTI and SP3 using correct ECEF intersection
% Inputs:
%   ROTI_array       - Nx32 ROTI array (NaN for missing)
%   receiver_xyz     - 1x3 receiver ECEF (meters)
%   start_epoch      - row index of first epoch to process
%   end_epoch        - row index of last epoch to process
% Output:
%   ipp_data.lat, ipp_data.lon - matrices of size num_epochs x 32 (degrees)

    T.Properties.VariableNames = matlab.lang.makeValidName(T.Properties.VariableNames);
    var_names = T.Properties.VariableNames;

    % Crop SP3 table to match requested epoch range
    T = T(start_epoch:end_epoch, :);

    num_epochs = size(ROTI_array,1);
    num_prns   = size(ROTI_array,2);

    ipp_lat_deg = nan(num_epochs, num_prns, 'single');
    ipp_lon_deg = nan(num_epochs, num_prns, 'single');

    rec = double(receiver_xyz(:))'; % 1x3 ECEF meters
    R_earth = 6378137; % WGS84 radius (m)
    H_ion_m = 350e3;   % ionospheric shell height (m)

    for k = 1:num_epochs
        rot_row = ROTI_array(k,:);
        prn_valid = find(~isnan(rot_row));
        if isempty(prn_valid), continue; end

        % Extract satellite ECEF for valid PRNs
        sat_xyz = nan(length(prn_valid),3);
        for idx = 1:length(prn_valid)
            prn = prn_valid(idx);
            prn_str = sprintf('G%02d', prn);
            x_col = find(strcmp(var_names, [prn_str '_X']), 1);
            y_col = find(strcmp(var_names, [prn_str '_Y']), 1);
            z_col = find(strcmp(var_names, [prn_str '_Z']), 1);
            if ~isempty(x_col) && ~isempty(y_col) && ~isempty(z_col)
                sat_xyz(idx,:) = [T{k,x_col}, T{k,y_col}, T{k,z_col}];
            end
        end

        for idx = 1:length(prn_valid)
            sat = sat_xyz(idx,:);
            d = sat - rec;              
            S = sum(d.^2);
            r_dot_d = dot(rec, d);
            r_norm2 = sum(rec.^2);
            R_ion2 = (R_earth + H_ion_m)^2;

            % Intersection scalar along line-of-sight
            D = (-r_dot_d + sqrt(r_dot_d^2 + (R_ion2 - r_norm2)*S)) / S;

            % IPP ECEF
            ipp_ecef = rec + D*d;

            % Convert to geodetic lat/lon
            lla = ecef2lla(ipp_ecef);  % [lat, lon, alt]
            ipp_lat_deg(k, prn_valid(idx)) = lla(1);
            ipp_lon_deg(k, prn_valid(idx)) = lla(2);
        end
    end

    ipp_data = struct('lat', ipp_lat_deg, 'lon', ipp_lon_deg);
end
