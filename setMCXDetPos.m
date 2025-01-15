function [detpos, num] = setMCXDetPos(cfg, SDS, detectorRadius, detectorHeight, varargin)
%%
% 球形探测器位置计算程序: 根据检测器的半径和num，计算检测器的x和y坐标
%   Input:
%     cfg: 仿真设置
%     SDS(mm): 探测器距离中心的半径
%     detectorRadius(mm): 探测器的半径
%     detectorHeight(mm): 探测器高度
%     num: 探测器个数
%   Output:
%     detpos: 计算后的检测器位置
%%
p = inputParser;
addRequired(p, 'cfg');
addRequired(p, 'SDS');
addRequired(p, 'detectorRadius');
addRequired(p, 'detectorHeight');
addOptional(p, 'num', 0);
addOptional(p, 'arcStep', 1);
parse(p, SDS, detectorRadius, detectorHeight, varargin{:});

%%
% 单位转换
SDS = SDS ./ cfg.unitinmm;
detectorHeight = detectorHeight / cfg.unitinmm;
[M, N, ~] = size(cfg.vol);

if strcmp(varargin{1}, 'num')
    num = varargin{2};
    angles = 0:2 * pi / num:2 * pi * (1 - 1 / num);
    detpos = zeros(length(SDS) * num, 4); % detector poistion [x, y, z, radius]
    for i = 0:length(SDS) - 1
        for j = 1:length(angles)
            detpos(num * i + j, 1) = M / 2 + SDS(i + 1) * cos(angles(j));
            detpos(num * i + j, 2) = N / 2 + SDS(i + 1) * sin(angles(j));
            detpos(num * i + j, 3) = detectorHeight;
            detpos(num * i + j, 4) = detectorRadius;
        end
    end
elseif strcmp(varargin{1}, 'arcStep')
    s = varargin{2} / cfg.unitinmm;
    detpos = zeros(0);
    for i = 0:length(SDS) - 1
        % theta = asin(detectorRadius/2/SDS(i+1))*4 + s/SDS(i+1); %不重叠铺球计算
        theta = s / SDS(i + 1);
        num(i + 1) = fix(2 * pi / theta);
        angles = linspace(0, 2 * pi, num(i + 1));

        for j = 1:length(angles)
            x = M / 2 + SDS(i + 1) * cos(angles(j));
            y = N / 2 + SDS(i + 1) * sin(angles(j));
            h = detectorHeight;
            r = detectorRadius;
            detpos(end + 1, :) = [x, y, h, r];
        end
    end
else
    error("请输入每个环的检测器个数或者检测器的间隔弧长");
end
end
