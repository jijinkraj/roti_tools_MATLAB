function fl = dt2row(ts, te)
    ss = sprintf('%06d', ts);
    ee = sprintf('%06d', te);
    s = duration(str2double(ss(1:2)), str2double(ss(3:4)), str2double(ss(5:6)));
    e = duration(str2double(ee(1:2)), str2double(ee(3:4)), str2double(ee(5:6)));
    fl = [(seconds(s)/30)+1, (seconds(e)/30)+1];
end
