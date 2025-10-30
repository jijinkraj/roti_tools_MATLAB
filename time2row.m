function row_idx = time2row(hh, mm, ss)
    % Convert time to row index in 30s-sampled data
    % 1 row = 00:00:00, 2 row = 00:00:30, etc.
    total_sec = hh*3600 + mm*60 + ss;
    row_idx = floor(total_sec / 30) + 1;
end
