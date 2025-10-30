function [tec_file_data, receiver_xyz] = parseTECfile(filename,e1,e2)

    % Check filename
    if nargin < 1 || isempty(filename)
        error('A valid filename must be provided.');
    end

    % Determine e1 and e2
    if nargin < 3 || isempty(e1) || isempty(e2)
        ts = input('Enter start time (hhmmss): ');
        te = input('Enter end time (hhmmss): ');
        fl = dt2row(ts, te);  % convert times to row indices
        e1 = fl(1);
        e2 = fl(2);
    end

    tec_file_data = {};  

    if nargin < 2
        e1 = 1;
        e2 = inf;
    end
    fid = fopen(filename,'r');
    if fid==-1, error('Cannot open file: %s',filename); end

    receiver_xyz = NaN(1,3,'single');

    while ~feof(fid)
        tline = fgetl(fid);
        if ~ischar(tline), continue; end
        if length(tline)>=80 && strcmp(tline(61:80),'APPROX POSITION XYZ ')
            receiver_xyz = single(sscanf(tline,'%f %f %f',3))';
        end
        if contains(tline,'END OF HEADER'), break; end
    end

    epoch_count = 0;
    while ~feof(fid)
        tline = fgetl(fid);
        if ~ischar(tline) || isempty(tline), continue; end

        % First 8 floats: datetime + dummy + Nsat
        [floats, count, ~, next_index] = sscanf(tline,'%f',8);
        if count<8, continue; end

        % Datetime
        year   = 2000 + floats(1);
        month  = floats(2);
        day    = floats(3);
        hour   = floats(4);
        minute = floats(5);
        second = floats(6);
        current_epoch = datetime(year,month,day,hour,minute,second);

        % Number of satellites
        nsat = floats(8);
        if nsat < 1, continue; end

        % Extract PRNs
        prn_string = strtrim(tline(next_index:end));
        prn_tokens = regexp(prn_string,'\d+','match'); 
        if numel(prn_tokens)<nsat, continue; end
        prns = single(str2double(prn_tokens(1:nsat)));

        % Read TEC values
        tec_values = zeros(1,nsat,'single');
        for i = 1:nsat
            data_line = fgetl(fid);
            if ~ischar(data_line) || isempty(data_line)
                tec_values(i) = NaN; continue;
            end
            data = sscanf(data_line,'%f');
            if numel(data)>=2 && data(2)==0
                tec_values(i) = single(data(1));
            else
                tec_values(i) = NaN;
            end
        end


        epoch_count = epoch_count + 1;
        tec_file_data{epoch_count,1} = current_epoch;
        tec_file_data{epoch_count,2} = prns;
        tec_file_data{epoch_count,3} = tec_values;
    end

    fclose(fid);

    if e1>1 || e2<epoch_count
        tec_file_data = tec_file_data(e1:min(e2,epoch_count),:);
    end
end
