function plot_roti_region(results, region_name)
% plot_roti_region(results, region_name)
% Prompts for hh:mm:ss, converts to epoch row (30 s sampling),
% pulls ROTI + IPP from results, filters to region, and plots.

    % ---- Regions ----
    regions = struct();
    regions.terra         = [-180, 180, -90,  90];
    regions.north_america = [-160,  -50,  20,  85];
    regions.south_america = [ -90,  -30, -60,  15];
    regions.europe        = [ -15,   60,  35,  75];
    regions.india         = [  65,  100,   5,  35];
    regions.china         = [  75,  135,  15,  55];
    regions.japan         = [ 125,  150,  20,  50];
    regions.africa        = [ -20,   55, -35,  35];
    regions.australia     = [ 110,  155, -45, -10];
    regions.russia        = [  30,  180,  40,  80];

    if ~isfield(regions, region_name)
        error('Region "%s" not defined.', region_name);
    end
    B = regions.(region_name);
    lon_min = B(1); lon_max = B(2);
    lat_min = B(3); lat_max = B(4);

    % ---- Ask time and map to row (30 s sampling) ----
    sample_interval_sec = 30;
    tstr = input('Enter epoch time (hh:mm:ss): ', 's');
    t = sscanf(tstr, '%d:%d:%d');
    if numel(t) ~= 3
        error('Invalid time format. Use hh:mm:ss');
    end
    hh = t(1); mm = t(2); ss = t(3);
    hhs = 0; mms = 0; sss = 0;
    epoch_row = floor((hh*3600 + mm*60 + ss)/sample_interval_sec)...
        - floor((hhs*3600 + mms*60 + sss)/sample_interval_sec);

    % ---- Collect points across all files (robust to empty/mismatched cells) ----
    all_lats  = [];
    all_lons  = [];
    all_rotis = [];

    for i = 1:numel(results.ROTI)
        % ROTI cell must be numeric matrix with enough rows
        if isempty(results.ROTI{i}) || ~ismatrix(results.ROTI{i})
            continue
        end
        if epoch_row > size(results.ROTI{i}, 1)
            continue
        end

        % IPP cell must be a struct with fields lat/lon
        ipp_i = results.IPP{i};
        if isempty(ipp_i) || ~isstruct(ipp_i) || ~isfield(ipp_i,'lat') || ~isfield(ipp_i,'lon')
            continue
        end
        if epoch_row > size(ipp_i.lat,1) || epoch_row > size(ipp_i.lon,1)
            continue
        end

        roti_row = results.ROTI{i}(epoch_row, :);
        lat_row  = ipp_i.lat(epoch_row, :);
        lon_row  = ipp_i.lon(epoch_row, :);

        valid = ~isnan(roti_row) & ~isnan(lat_row) & ~isnan(lon_row);
        if any(valid)
            all_lats  = [all_lats,  lat_row(valid)];
            all_lons  = [all_lons,  lon_row(valid)];
            all_rotis = [all_rotis, roti_row(valid)];
        end
    end

    if isempty(all_lats)
        error('No valid ROTI/IPP data available at %02d:%02d:%02d.', hh, mm, ss);
    end

    % ---- Region filter ----
    in_reg = all_lats >= lat_min & all_lats <= lat_max & ...
         all_lons >= lon_min & all_lons <= lon_max; %& ...
         %all_rotis <= 1;   % <-- filter values > 1

    if ~any(in_reg)
        error('No data points in region "%s" at %02d:%02d:%02d.', region_name, hh, mm, ss);
    end

    lats  = all_lats(in_reg);
    lons  = all_lons(in_reg);
    rotis = all_rotis(in_reg);

    % ---- Sort ROTI ----
    [rotis, sort_idx] = sort(rotis);
    lats = lats(sort_idx);
    lons = lons(sort_idx);

    % ---- Plot ----
    figure;
    if strcmp(region_name,'terra')
        worldmap('World');
    else
        worldmap([lat_min lat_max], [lon_min lon_max]);
    end
    load coastlines
    plotm(coastlat, coastlon, 'k'); hold on;

    scatterm(lats, lons, 150, rotis, 's', 'filled');

    % simple 4-color ramp
    cmap = [0 0 1; 0 1 0; 1 1 0; 1 0 0];
    colormap(interp1(linspace(0,1,4), cmap, linspace(0,1,256)));
    colorbar;
    %caxis([0 1]);

    title(sprintf('ROTI (%s) at %02d:%02d:%02d', ...
        region_name, hh, mm, ss), 'Interpreter','none');
end
