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
parse(p, cfg, detp, varargin{:});

%% 处理环检测器
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
        [detp, idNum] = MCXSetRingDetid(detp,center,SDS,SDSWidth);
    else
        for i = 1:size(p.Results.mask,3)
            photonsInMask = getPhotonsInMask(detp.p(:,1:2), ...
                p.Results.mask(:,:,i));
            detp.detid(photonsInMask) = i;
        end

        idNum = size(p.Results.mask, 3);
    end
else
    idNum = size(cfg.detpos,1);
end

%% 读取数据
energy = zeros(1, idNum);
absorbance = zeros(1, idNum);
detPath = zeros(-1, idNum);
detWeight = mcxdetweight(detp, cfg.prop, cfg.unitinmm);  % 计算被探测到时的光子重量

for i = 1:idNum    % 探测器编号

    currentWeight = detWeight(detp.detid == i);
    energy(i) = sum(currentWeight);
    absorbance(i) = -log(energy(i) / cfg.nphoton);
    % absorbance(i) = -log(sum(currentWeight));

    for j = 2:size(detp.prop, 1)
        ppath = detp.data(j, :)';
        detPath(j - 1, i) = sum(ppath(detp.detid == i) .* currentWeight .* cfg.unitinmm) / energy(i);
    end
end

% 添加表头
if ~isempty(SDS)
    tableHeader = arrayfun(@(x) ['检测器' num2str(x)], SDS.*cfg.unitinmm, 'UniformOutput', false);
else
    tableHeader = arrayfun(@(x) ['检测器' num2str(x)], 1:idNum, 'UniformOutput', false);
end

rowHeader = arrayfun(@(x) ['介质' num2str(x)], 1:size(detPath, 1), 'UniformOutput', false);

energy = array2table(energy, 'VariableNames', tableHeader);
absorbance = array2table(absorbance, 'VariableNames', tableHeader);
detPath = array2table(detPath, 'VariableNames', tableHeader, 'RowNames', rowHeader);

end
