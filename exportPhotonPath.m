function res = exportPhotonPath(cfg, seeds, detp, varargin)
%% 设置输入检测
p = inputParser;
addRequired(p, 'cfg');
addRequired(p, 'detp');
addOptional(p, 'SDS', [1.7, 2.0, 2.3, 2.6, 2.9]);
addOptional(p, 'width', 0.2);
addOptional(p, 'numWorkers', 8);
parse(p, cfg, detp, varargin{:});
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

%% 计算光子计数
out = {};
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

    grids = zerosLike(cfg.vol);
    % 获取光子数量
    numPhotons = length(detp2.detid);

    % 划分光子轨迹数据范围
    numWorkers = gcp('nocreate').NumWorkers; % 获取并行池中工作线程数
    chunks = ceil(numPhotons / numWorkers);

    % 使用 parfor 均分数据并计算局部网格
    parfor workerIdx = 1:numWorkers
        % 计算当前线程负责的光子 ID 范围
        photonStart = (workerIdx - 1) * chunks + 1;
        photonEnd = min(workerIdx * chunks, numPhotons);

        % 初始化局部网格
        localGrids = zeros(size(grids));

        % 遍历当前线程负责的光子范围
        for i = photonStart:photonEnd
            % 提取光子的运动轨迹并网格化
            pos = ceil(traj.pos(traj.id == i, :));

            % 遍历光子路径
            for j = 2:size(pos, 1)
                % 获取两点之间的连线体素
                voxels = bresenham3D(pos(j-1,:), pos(j,:));
                
                % 累加体素到局部网格
                for v = 1:size(voxels, 1)
                    localGrids(voxels(v, 1), voxels(v, 2), voxels(v, 3)) = ...
                        localGrids(voxels(v, 1), voxels(v, 2), voxels(v, 3)) + 1;
                end
            end
        end

        % 保存局部网格到结果集合
        allLocalGrids{workerIdx} = localGrids; 
    end

    % 合并所有局部网格到全局网格
    for workerIdx = 1:numWorkers
        grids = grids + allLocalGrids{workerIdx};
    end
    
    % 将grids保存为一个mat文件
    save(['grids-' num2str(detid) '.mat'], "grids")

end

end

function voxels = bresenham3D(startPoint, endPoint)
    % Bresenham 算法计算两点连线经过的体素
    startPoint = round(startPoint);
    endPoint = round(endPoint);
    
    % 计算步长和差值
    diff = abs(endPoint - startPoint);
    step = sign(endPoint - startPoint);
    maxDiff = max(diff);
    t = 0.5; % 初始误差
    
    % 初始化体素坐标
    voxels = [];
    currentPoint = startPoint;
    
    for i = 1:maxDiff+1
        % 添加当前点到路径
        voxels = [voxels; currentPoint];
        for dim = 1:3
            t(dim) = t(dim) + diff(dim);
            if t(dim) >= maxDiff
                currentPoint(dim) = currentPoint(dim) + step(dim);
                t(dim) = t(dim) - maxDiff;
            end
        end
    end
end
