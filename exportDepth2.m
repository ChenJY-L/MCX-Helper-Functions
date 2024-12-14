function [out, meanDepth, outPPath] = exportDepth2(cfg, seeds, detp, thresh, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  func: 导出仿真的穿透深度
%
%  Input: 
%   cfg: 仿真参数设置
%   seeds: 光子种子的集合
%   detp: 探测光子集合
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
addOptional(p, 'savepath',[]);
addOptional(p, 'numWorkers', 8);
addOptional(p, 'layers', []);
parse(p, cfg, detp, varargin{:});

savepath = p.Results.savepath;
M = p.Results.numWorkers;
layers = p.Results.layers;
%% 处理环检测器
if ~isempty(varargin)
    SDS = p.Results.SDS / cfg.unitinmm;
    SDSWidth = p.Results.width / cfg.unitinmm; 
    
    % 重新计算detid
    center = size(cfg.vol,[1,2])/2; % 计算中心点坐标 (是否需要+0.5?)
    
    [detp, idNum] = MCXSetRingDetid(detp,center,SDS,SDSWidth);
else
    idNum = length(cfg.detpos);
end

%% 导出最大穿透深度
% 计算中心的位置
center = size(cfg.vol, [1,2])./2;
out = zeros(0);
outPPath = zeros(0);

% 计算被探测到时的光子重量
meanDepth = zeros(1,idNum);
errorDet = zeros(1,idNum);
detWeights = mcxdetweight(detp, cfg.prop, cfg.unitinmm);

for detid = 1:idNum
    % 使用MCX对光子进行replay
    photons = find(detp.detid == detid & detWeights > thresh);
    
    if isempty(photons)
        continue
    end

    newcfg = cfg;
    newcfg.respin = 1;
    newcfg.seed = seeds.data(:,photons);
    newcfg.outputtype = 'jacobian';
    newcfg.detphotons = detp.data(:,photons);
    newcfg.maxjumpdebug = 1e7;
    [f, detp2, ~, ~, traj] = mcxlab(newcfg);
    
    [ppath1, index] = sortrows(detp.ppath(photons, :), [1,2,3]);
    ppath2 = sortrows(detp2.ppath, [1,2,3]);

    if find(ppath1 == ppath2)
        detWeight = mcxdetweight(detp2, cfg.prop, cfg.unitinmm);
        errorDet(detid) = 1;
    else
        detWeight = detWeights(index);
        errorDet(detid) = 0;
    end
    
    if isempty(varargin)
        % 使用球形检测器时，计算检测器的SDS
        d = norm(cfg.detpos(detid, 1:2) - center);
    else
        if detid == -1
            % 光子detid为-1，表面该光子未被环形检测器探测
            d = NaN;  
        else
            % 记录检测器id
            d = SDS(detid);
        end
    end
    
    depths = zeros(1, length(detp2.detid));
    weights = zeros(1, length(detp2.detid));
    pathTraj = zeros(numel(layers), length(detp2.detid));
    parfor (i = 0:length(detp2.detid) - 1, M)
        % 提取某个光子的全部运动轨迹
        pos = traj.pos(traj.id == i,:);
        
        % 提取光子的最后能量
        idx = find(traj.id == i, 1, 'last');
        
        % 提取运动过程中，最大的z坐标
        if ~isempty(layers)
            pathTraj(:, i+1) = calculatePPath(pos, layers, detp2.prop);
        end
        depths(i+1) = max(pos(:,3));
        weights(i+1) = traj.data(5,idx);
    end
    detids = ones(1,length(detp2.detid))*detid;
    distances = ones(1,length(detp2.detid))*d.*cfg.unitinmm;
    
    if isempty(layers)
        tmp1 = [detids; distances; depths; weights];
    else
        tmp1 = [detids; distances; depths; weights; pathTraj .* cfg.unitinmm];
    end

    tmp2 = [detids;distances;detWeight';detp2.ppath'.*cfg.unitinmm];

    out = [out, tmp1];
    outPPath = [outPPath, tmp2];
    
    % 计算加权平均穿透深度
    try
        meanDepth(detid) = sum(weights(:).*depths(:))/sum(weights(:));
    catch
        meanDepth(detid) = 0; 
    end

    % 保存轨迹的mat文件
    if ~isempty(savepath)  
        try
            save(fullfile(savepath, ['traj-' num2str(d*cfg.unitinmm) '.mat']), "traj")
        catch
            mkdir(savepath)
            save(fullfile(savepath, ['traj-' num2str(d*cfg.unitinmm) '.mat']), "traj")
        end
    end
end
out(3,:) = out(3,:) .* cfg.unitinmm;    % 深度

meanDepth = meanDepth .* cfg.unitinmm;
meanDepth = [meanDepth;errorDet];
out = out';
out = sortrows(out, [1,2]);

outPPath = outPPath';
% 添加表头
tableHeader = {'检测器ID', 'SDS(mm)', '最大穿透深度(mm)', '光能量(traj)'};
if ~isempty(layers)
    for i = 1:numel(layers)
        tableHeader{end + 1} = ['介质', num2str(i), '(mm)'];
    end
end
out = array2table(out,"VariableNames",tableHeader);

tableHeader = {'检测器ID', 'SDS(mm)', '光能量(ppath)'};
for i = 1:size(cfg.prop,1) - 1
    tableHeader{end + 1} = ['介质', num2str(i)];
end
outPPath = array2table(outPPath, "VariableNames", tableHeader);
end


function ppath = calculatePPath(pos, layers, prop)
ppath = zeros(numel(layers), 1);
n = prop(:, 4);
layersZ = [0; cumsum(layers')]; % 各层的分界Z坐标，包括初始层0

% 初始化当前层
currentLayer = find(pos(1, 3) <= layersZ, 1) - 1; % 找到光子初始所在层
currentN = n(currentLayer); % 当前折射率
for i = 2:length(pos)
    % 判断光子是否进入了新的层
    while pos(i, 3) > layersZ(currentLayer + 1)
        currentLayer = currentLayer + 1; % 更新当前层
        if currentLayer > numel(layers) % 超过最深层
            currentLayer = numel(layers); % 限制为最深层
            break;
        end
        currentN = n(currentLayer); % 更新折射率
    end
    
    while pos(i, 3) < layersZ(currentLayer)
        currentLayer = currentLayer - 1; % 回到上一层
        if currentLayer <= 0 % 超过最浅层
            currentLayer = 1; % 限制为最浅层
            currentN = n(currentLayer); % 更新折射率为第一层
            break;
        end
        currentN = n(currentLayer); % 更新折射率
    end
    
    dis = norm(pos(i, :) - pos(i - 1, :)) * currentN;   % 计算光程
    ppath(currentLayer) = ppath(currentLayer) + dis;    % 光程累加
end

end