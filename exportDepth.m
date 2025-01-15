function [out, meanDepth] = exportDepth(cfg, seeds, detp, thresh, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  func: 导出仿真的穿透深度
%
%  Input:
%   cfg: 仿真参数设置
%   seeds: 光子种子的集合
%   detp: 探测光子集合
%   thresh: 光能量阈值
%   'SDS'(mm): 数组存储环的中心半径
%   'width'(mm): 环的宽度
%
%  Output:
%   out(nphoton,3): 第一列是每个光子的穿透深度(mm)，第二列是每个光子的SDSid，
%   第三列是每个光子对应的SDS半径(mm)
%
%  程序说明:
%   使用第一次仿真中导出的被探测到光子的种子，对光子在介质中的传播路径进行重现。
%   提取了光子运动时，z坐标的最大值作为该光子的最大穿透深度。使用环状检测器时，
%   需要按照如下格式调用函数
%   `out = exportMaximumDepth(cfg, seeds, detp, 'SDS', SDS, 'width', SDSWidth);`
%   此时，程序会根据每个光子第一次仿真时出射的位置，重新设置检测器id。
%
%   *BUG*: 使用环状检测器进行replay时，输入的光子和最终被探测到的光子个数不同
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 设置输入检测
p = inputParser;
addRequired(p, 'cfg');
addRequired(p, 'detp');
addOptional(p, 'SDS', [1.7, 2.0, 2.3, 2.6, 2.9]);
addOptional(p, 'width', 0.2);
parse(p, cfg, detp, varargin{:});

%% 使用MCX对光子进行replay
newcfg = cfg;
newcfg.seed = seeds.data;
newcfg.outputtype = 'jacobian';
newcfg.detphotons = detp.data;
[~, detp2, ~, ~, traj] = mcxlab(newcfg);

%% 处理环检测器
if ~isempty(varargin)
    SDS = p.Results.SDS / cfg.unitinmm;
    width = p.Results.width / cfg.unitinmm;

    % 重新计算detid
    center = size(cfg.vol, [1, 2]) / 2; % 计算中心点坐标 (是否需要+0.5?)

    pos = detp2.p(:, 1:2) - center;
    distance = sqrt(pos(:, 1).^2 + pos(:, 2).^2);

    for i = 1:length(SDS)
        id = (distance >= (SDS(i) - width / 2)) & (distance < (SDS(i) + width / 2));
        detp2.detid(id) = i;
    end
    idNum = length(SDS);
else
    idNum = length(cfg.detpos);
end

%% 导出最大穿透深度
% 计算中心的位置
center = size(cfg.vol, [1, 2]) ./ 2;
out = zeros(4, length(detp2.detid));

% 计算被探测到时的光子重量
detWeight = mcxdetweight(detp, cfg.prop, cfg.unitinmm);
for i = 0:length(detp2.detid) - 1
    % 提取某个光子的全部运动轨迹
    idx = (traj.id == i) & (detWeight >= thresh);
    pos = traj.pos(idx, :);
    detid = detp2.detid(i + 1);    % 光子对应的检测器id

    % 提取运动过程中，最大的z坐标
    out(1, i + 1) = detid;
    out(3, i + 1) = max(pos(:, 3));
    out(4, i + 1) = detWeight(i + 1);

    if isempty(varargin)
        % 使用球形检测器时，计算检测器的SDS
        out(2, i + 1) = norm(cfg.detpos(detid, 1:2) - center);

    else
        if detid == -1
            % 光子detid为-1，表面该光子未被环形检测器探测
            out(2, i + 1) = NaN;

        else
            % 记录检测器id
            out(2, i + 1) = SDS(detid);
        end
    end
end

out(2, :) = out(2, :) .* cfg.unitinmm;    % SDS
out(3, :) = out(3, :) .* cfg.unitinmm;    % 深度
out = out';
out = sortrows(out, [2, 1]);

%% 计算加权平均穿透深度

meanDepth = zeros(1, idNum);
for id = 1:idNum
    idx = find(detp2.detid == id);
    w = detWeight(idx);
    l = out(idx, 1);
    meanDepth(id) = sum(w .* l) / sum(w);
end

end
