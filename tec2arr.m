function tec_array = tec2arr(tec_file_data)
%TEC2ARR Convert parsed TEC cell data into an Nx32 numeric array.
%
%   tec_array = tec2arr(tec_file_data)
%
% Input:
%   tec_file_data - Cell array output from parseTECfile {epoch, prns, tec_values}
%
% Output:
%   tec_array     - [N x 32] array of TEC values, NaN where no data
%
% Notes:
%   - Uses ALL epochs in tec_file_data.
%   - Assumes PRNs are in the range 1–32.

    num_epochs = size(tec_file_data,1);
    tec_array  = NaN(num_epochs, 32, 'single');

    for epoch_idx = 1:num_epochs
        prns = tec_file_data{epoch_idx,2};
        tec  = tec_file_data{epoch_idx,3};
        if ~isempty(prns) && ~isempty(tec)
            tec_array(epoch_idx, prns) = tec;
        end
    end
end
