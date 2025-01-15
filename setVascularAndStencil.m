function VSsettings = setVascularAndStencil()

Position_upperandrt = 23 + 40; % 上血网及乳突起始z坐标

R_upper = 1.5;  % 上血网血管半径(e.g. 1.5*10 um=15 um)
Interval_upper = 15; % 上血网间距

R_rt = 0.5;  % 乳突血管半径
Length_rt3 = 4.5; % 乳突瓣长
Height_rt = 15; % 乳突高度
Interval_rt = 20; % 乳突间距

gw_height = 15; % 钢网高度0.15mm
gw_width = 10; % 钢网宽度0.1mm
gw_interval = 50; % 钢网间隔0.5mm
gw_initial_z = 55; % 钢网起始z位置

%% 血管网设置

% 设置上血网血管网
upper_initial_value = 0;
upper_increment = Interval_upper;
upper_max_value = size(cfg.vol, 1);
% 设置乳突血管网1
rt1_initial_value1 = 0;
rt1_initial_value2 = 0;
rt1_increment1 = Interval_rt;
rt1_increment2 = Interval_upper;
rt1_max_value1 = size(cfg.vol, 1);
rt1_max_value2 = size(cfg.vol, 1);
% 设置乳突血管网2
rt2_initial_value1 = Length_rt3;
rt2_initial_value2 = 0;
rt2_increment1 = Interval_rt;
rt2_increment2 = Interval_upper;
rt2_max_value1 = size(cfg.vol, 1);
rt2_max_value2 = size(cfg.vol, 1);
% 设置乳突血管网3
rt3_initial_value1 = Length_rt3;
rt3_initial_value2 = 0;
rt3_increment1 = Interval_rt;
rt3_increment2 = Interval_upper;
rt3_max_value1 = size(cfg.vol, 1);
rt3_max_value2 = size(cfg.vol, 1);
% 设置钢网1
gw1_initial_value1 = 15;
gw1_increment1 = gw_interval;
gw1_max_value1 = size(cfg.vol, 1);
% 设置钢网2
gw2_initial_value1 = 15;
gw2_increment1 = gw_interval;
gw2_max_value1 = size(cfg.vol, 1);

%% 设置上血网血管网 存储字符串的数组
upperstrings = {};
% 循环生成字符串
for current_value = upper_initial_value:upper_increment:upper_max_value
    % 构造C0和C1中的数值
    C0 = [0, current_value, Position_upperandrt];
    C1 = [size(cfg.vol, 1), current_value, Position_upperandrt];
    % 构造JSON格式的字符串
    j_string = sprintf('{"Cylinder": {"Tag":9, "C0": [%d,%d,%d], "C1": [%d,%d,%d], "R": %d}},', ...
                       C0(1), C0(2), C0(3), C1(1), C1(2), C1(3), R_upper);
    % 将字符串添加到数组中
    upperstrings{end + 1} = j_string;
end
VSsettings.upper = join(upperstrings);

% 设置乳突血管网1 存储字符串的数组
rt1strings = {};
% 循环生成字符串
for current_value1 = rt1_initial_value1:rt1_increment1:rt1_max_value1
    for current_value2 = rt1_initial_value2:rt1_increment2:rt1_max_value2
        % 构造C0和C1中的数值
        C0 = [current_value1, current_value2, Position_upperandrt - Height_rt];
        C1 = [current_value1, current_value2, Position_upperandrt];
        % 构造JSON格式的字符串
        j_string = sprintf('{"Cylinder": {"Tag":9, "C0": [%d,%d,%d], "C1": [%d,%d,%d], "R": %d}},', ...
                           C0(1), C0(2), C0(3), C1(1), C1(2), C1(3), R_rt);
        % 将字符串添加到数组中
        rt1strings{end + 1} = j_string;
    end
end
VSsettings.rutu1 = join(rt1strings);

% 设置乳突血管网2 存储字符串的数组
rt2strings = {};
% 循环生成字符串
for current_value1 = rt2_initial_value1:rt2_increment1:rt2_max_value1
    for current_value2 = rt2_initial_value2:rt2_increment2:rt2_max_value2
        % 构造C0和C1中的数值
        C0 = [current_value1, current_value2, Position_upperandrt - Height_rt];
        C1 = [current_value1, current_value2, Position_upperandrt];
        % 构造JSON格式的字符串
        j_string = sprintf('{"Cylinder": {"Tag":9, "C0": [%d,%d,%d], "C1": [%d,%d,%d], "R": %d}},', ...
                           C0(1), C0(2), C0(3), C1(1), C1(2), C1(3), R_rt);
        % 将字符串添加到数组中
        rt2strings{end + 1} = j_string;
    end
end
VSsettings.rutu2 = join(rt2strings);

% 设置乳突血管网3 存储字符串的数组
rt3strings = {};
% 循环生成字符串
for current_value1 = rt3_initial_value1:rt3_increment1:rt3_max_value1
    for current_value2 = rt3_initial_value2:rt3_increment2:rt3_max_value2
        % 构造C0和C1中的数值
        C0 = [current_value1, current_value2, Position_upperandrt - Height_rt];
        C1 = [current_value1 - rt2_initial_value1, current_value2, Position_upperandrt - Height_rt];
        % 构造JSON格式的字符串
        j_string = sprintf('{"Cylinder": {"Tag":9, "C0": [%d,%d,%d], "C1": [%d,%d,%d], "R": %d}},', ...
                           C0(1), C0(2), C0(3), C1(1), C1(2), C1(3), R_rt);
        % 将字符串添加到数组中
        rt3strings{end + 1} = j_string;
    end
end
VSsettings.rutu3 = join(rt3strings);

% 设置钢网1 存储字符串的数组
gw1strings = {};
% 循环生成字符串
for current_value1 = gw1_initial_value1:gw1_increment1:gw1_max_value1

    % 构造C0和C1中的数值
    C0 = [0, current_value1, gw_initial_z - gw_height];
    C1 = [size(cfg.vol, 1), gw_width, gw_height];
    % 构造JSON格式的字符串
    j_string = sprintf('{"Box": {"Tag":9, "O": [%d,%d,%d], "Size": [%d,%d,%d]}},', ...
                       C0(1), C0(2), C0(3), C1(1), C1(2), C1(3));
    % 将字符串添加到数组中
    gw1strings{end + 1} = j_string;

end
VSsettings.gw1 = join(gw1strings);

% 设置钢网1 存储字符串的数组
gw2strings = {};
% 循环生成字符串
for current_value1 = gw2_initial_value1:gw2_increment1:gw2_max_value1

    % 构造C0和C1中的数值
    C0 = [current_value1, 0, gw_initial_z - gw_height];
    C1 = [gw_width, size(cfg.vol, 1), gw_height];
    % 构造JSON格式的字符串
    j_string = sprintf('{"Box": {"Tag":9, "O": [%d,%d,%d], "Size": [%d,%d,%d]}},', ...
                       C0(1), C0(2), C0(3), C1(1), C1(2), C1(3));
    % 将字符串添加到数组中
    gw2strings{end + 1} = j_string;
end
VSsettings.gw2 = join(gw2strings);
end
