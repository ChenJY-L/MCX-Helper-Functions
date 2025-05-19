function [energy, absorbance, detPath] = exportAbsorbance(cfg, detp, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   func: 导出系统的吸光度
%
%   Input:
%       cfg: 仿真参数设置
%       detp: 探测光子集合
%       'SDS'(mm): 数组存储环的中心半径
%       'width'(mm): 环的宽度
%       'center': 自定义的中心坐标 (可选)
%
%   Output:
%       absorbance(1): 各个探测器吸光度 -log（探测光子重量/总光子重量）
%       detPath(mm): 各个探测器探测到光子在各层介质中的平均路径长度
%
%   程序说明:
%       探测器探测到的光子重量需要根据吸收系数和运动距离（无量纲）
%       被探测到重量 = 初始重量*exp(ua*pathlength*unitinmm)
%       可使用MCXLAB工具包中的mcxdetweight计算
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 设置输入检测
p = inputParser;
addRequired(p, 'cfg');
addRequired(p, 'detp');
addOptional(p, 'SDS', []);
addOptional(p, 'width', 0.2);
addOptional(p, 'center', []);  % 添加'center'为可选输入
addOptional(p, 'mask', []);
addOptional(p, 'isexporttable', true);
parse(p, cfg, detp, varargin{:});

%% 处理环检测器
SDS = [];
if ~isempty(varargin)
    SDS = p.Results.SDS / cfg.unitinmm;
    SDSWidth = p.Results.width / cfg.unitinmm;

    % 使用提供的center值，若没有提供则使用默认方法计算
    if isempty(p.Results.center)
        center = size(cfg.vol, [1, 2]) / 2;  % 默认计算中心点
    else
        center = p.Results.center;  % 使用用户提供的center值
    end

    if isempty(p.Results.mask)
        [detp, idNum] = MCXSetRingDetid(detp, center, SDS, SDSWidth);
    else
        for i = 1:size(p.Results.mask, 3)
            photonsInMask = getPhotonsInMask(detp.p(:, 1:2), ...
                                             p.Results.mask(:, :, i));
            detp.detid(photonsInMask) = i;
        end

        idNum = size(p.Results.mask, 3);
    end
else
    idNum = size(cfg.detpos, 1);
end

%% 读取数据
detWeight = mcxdetweight(detp, cfg.prop, cfg.unitinmm);  % 计算被探测到时的光子重量
numMedia = size(detp.ppath, 2);
validPhotonIdx = find(detp.detid > 0 & detp.detid <= idNum);

% 提取有效光子的数据
validDetId     = detp.detid(validPhotonIdx);
validDetWeight = detWeight(validPhotonIdx);

% 提取有效光子在所有介质中的路径长度 (第2行到最后一行)
validPPathData = detp.ppath(validPhotonIdx, :)'; % numMedia x numValidPhotons

% energy = accumarray(validDetId(:), double(validDetWeight(:)), [])'; 
energy = accumarray(detp.detid(validPhotonIdx), double(detWeight(validPhotonIdx)), [])';
% --- 计算吸光度 (Absorbance) ---
absorbance = -log(energy / cfg.nphoton);
% 处理 energy 为 0 的情况，避免 log(0) = -Inf
absorbance(energy == 0) = Inf; % 或者可以设为 NaN

% --- 计算平均路径长度 (detPath) ---
% 初始化 detPath 为 numMedia x idNum
detPath = zeros(numMedia, idNum);
detPathWeightedSum = zeros(numMedia, idNum); % 存储加权路径之和

% 计算加权路径长度: ppath .* detWeight (在有效光子子集上操作)
weightedPPath = validPPathData .* validDetWeight'; % 结果是 numMedia x numValidPhotons

% 对每个介质层，使用 accumarray 计算加权路径之和
for iMedia = 1:numMedia
    % 对第 iMedia 层的加权路径 (weightedPPath(iMedia, :)) 按探测器ID求和
    detPathWeightedSum(iMedia, :) = accumarray(validDetId(:), weightedPPath(iMedia, :), [idNum 1])';
end

% 计算平均路径长度 = (加权路径之和 * unitinmm) / 总能量
energyRep = repmat(energy, numMedia, 1); % 复制有效能量
% 计算有效探测器的平均路径
detPath = (detPathWeightedSum * cfg.unitinmm) ./ energyRep;

%% 格式化输出为表格 
if p.Results.isexporttable
    % 添加表头
    if ~isempty(SDS)
        tableHeader = arrayfun(@(x) ['检测器' num2str(x)], SDS .* cfg.unitinmm, 'UniformOutput', false);
    else
        tableHeader = arrayfun(@(x) ['检测器' num2str(x)], 1:idNum, 'UniformOutput', false);
    end

    rowHeader = arrayfun(@(x) ['介质' num2str(x)], 1:size(detPath, 1), 'UniformOutput', false);

    energy = array2table(energy, 'VariableNames', tableHeader);
    absorbance = array2table(absorbance, 'VariableNames', tableHeader);
    detPath = array2table(detPath, 'VariableNames', tableHeader, 'RowNames', rowHeader);
end
end
