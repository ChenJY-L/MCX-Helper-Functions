function [ua, us, g, n, wavelength, nphotons] = readOpticalProperties(fileName, sheet)
opticalProperties = readtable(fileName, ...
                              "Sheet", sheet, ...
                              "NumHeaderLines", 0, ...
                              'ReadVariableNames', true, ...
                              'VariableNamingRule', 'preserve');
% opticalProperties = readtable(fileName);

% 读取所有列名
columnNames = opticalProperties.Properties.VariableNames;
uaColumns = startsWith(columnNames, 'ua');
usColumns = startsWith(columnNames, 'us');
gColumns = startsWith(columnNames, 'g');
nColumns = startsWith(columnNames, 'n');

ua = table2array(opticalProperties(:, uaColumns));
us = table2array(opticalProperties(:, usColumns));
g = table2array(opticalProperties(:, gColumns));
n = table2array(opticalProperties(:, nColumns));

wavelength = table2array(opticalProperties(:, 1));
if nargout > 5
    nphotons = table2array(opticalProperties.photon);
end
end
