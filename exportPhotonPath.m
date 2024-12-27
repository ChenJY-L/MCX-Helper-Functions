function res = exportPhotonPath(cfg, detp, seeds, slice, savePath, varargin)
%% 设置输入检测
p = inputParser;
addRequired(p, 'cfg');
addRequired(p, 'detp');
addOptional(p, 'SDS', [1.7, 2.0, 2.3, 2.6, 2.9]);
addOptional(p, 'width', 0.2);
addOptional(p, 'numWorkers', 6);
parse(p, cfg, detp, varargin{:});

%% 并行池初始化
if ~isempty(gcp('nocreate')) % 如果并行未开启
    delete(gcp('nocreate'))
end
parpool(p.Results.numWorkers);

%% 处理环检测器
if ~isempty(varargin)
    SDS = p.Results.SDS / cfg.unitinmm;
    SDSWidth = p.Results.width / cfg.unitinmm;

    % 重新计算detid
    center = size(cfg.vol,[1,2])/2; % 计算中心点坐标 (是否需要+0.5?)

    [detp, idNum] = MCXSetRingDetid(detp,center,SDS,SDSWidth);
else
    idNum = size(cfg.detpos, 1);
end

%% 计算光子计数
out = {};
for detid = 1:idNum
    % 使用MCX对光子进行replay
    photons = find(detp.detid == detid);

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

    grids = zeros(size(cfg.vol));
    % 获取光子数量
    numPhotons = length(detp2.detid);

    % 划分光子轨迹数据范围
    numWorkers = gcp('nocreate').NumWorkers; % 获取并行池中工作线程数
    chunks = ceil(numPhotons / numWorkers);

    % 使用 parfor 均分数据并计算局部网格
    for workerIdx = 1:numWorkers
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
            for j = 2:size(pos, 1) - 1
                % 获取两点之间的连线体素
                [X, Y, Z] = bresenham_line3d(pos(j-1,:) + 1, pos(j,:) + 1);

                % 累加体素到局部网格
                for v = 1:length(X)
                    localGrids(X(v), Y(v), Z(v)) = ...
                        localGrids(X(v), Y(v), Z(v)) + 1;
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
    grids = squeeze(grids(:, slice, :));
    % 将grids保存为一个mat文件
    saveFileName = sprintf('%s-grids-%g.mat',savePath, detid);
    save(saveFileName, "grids")

end

end

