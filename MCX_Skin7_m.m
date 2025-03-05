clear;
%[text:tableOfContents]{"heading":"**目录**"}
%[text] %[text:anchor:2151] ## Step0: 设置输出文件名称
savedataPath = sprintf("%s",datetime("now","Format","uuuu-MM-dd-HH-mm"));   % 使用时间作为文件夹名称
ballFilePath = "球形离散检测器.xlsx";
ringFilePath = "平面环状检测器.xlsx";
overFilePath = "重叠环状检测器.xlsx";
depthFilePath = "光子最大穿透深度.xlsx";
fluxFilePath = 'flux环状检测器.xlsx';
mkdir(savedataPath)
%%
%[text] %[text:anchor:7cde] ## Step1: Monte Carlo模拟参数
%[text] - 考虑带宽时，此处光子数的设置会无效。
%[text] - 选择保存后，会使用`savejd`将`detp`保存到文件中 \
step = 1;                         % 仿真步长 %[control:editfield:634c]{"position":[8,9]}
nIter = 2;                        % 迭代次数 %[control:editfield:6e4a]{"position":[9,10]}
cfg.respin = 1;                   % 重复次数 %[control:editfield:3273]{"position":[14,15]}
cfg.unitinmm = 0.01;                 % 网格单位 %[control:editfield:04d6]{"position":[16,20]}
cfg.seed = hex2dec("623F9A9E");            % 随机种子，保证重复性 %[control:editfield:6a1c]{"position":[20,30]}
cfg.nphoton = 5e6;                  % 光子数 %[control:editfield:8d20]{"position":[15,18]}
cfg.outputtype = 'flux' ;              % 输出类型 %[control:dropdown:0474]{"position":[18,24]}
issave = false;                                        % 是否保存仿真结果 %[control:checkbox:73cf]{"position":[10,15]}
isplot = false;                                        % 是否绘制中间步骤 %[control:checkbox:0bb6]{"position":[10,15]}
%%
%[text] %[text:anchor:1924] ### Step1\.0: 皮肤模型配置
%%
cfg.issrcfrom0 = double(true);                         % 1-第一个体素为[0 0 0]; 0-第一个体元为[1 1 1] %[control:checkbox:87ed]{"position":[25,29]}

layers(1) = 0.4; %[control:editfield:53fc]{"position":[13,16]}
layers(2) = 0.2; %[control:editfield:1862]{"position":[13,16]}
layers(3) = 0.02; %[control:editfield:8529]{"position":[13,17]}
layers(4) = 0.05; %[control:editfield:0e09]{"position":[13,17]}
layers(5) = 0.1; %[control:editfield:815d]{"position":[13,16]}
layers(6) = 0.08; %[control:editfield:2ca2]{"position":[13,17]}
layers(7) = 0.2; %[control:editfield:28d7]{"position":[13,16]}
layers(8) = 0.2; %[control:editfield:6132]{"position":[13,16]}
layers(9) = 0.2; %[control:editfield:20ce]{"position":[13,16]}
layers(10) = 0.2; %[control:editfield:8c68]{"position":[14,17]}
layers(11) = 0.2; %[control:editfield:5968]{"position":[14,17]}
layers(12) = 6.3; %[control:editfield:769b]{"position":[14,17]}

layers = layers./cfg.unitinmm;

gridX = 800; %[control:editfield:1de5]{"position":[9,12]}
gridY = 800; %[control:editfield:8993]{"position":[9,12]}
gridZ = sum(layers);
cfg.vol = zeros(gridX, gridY, gridZ);

cfg.shapes = makeSkinWithMask(cfg.vol, layers);
%%
%[text] %[text:anchor:9c37] ### Step1\.1: 光源设置
%[text] - 光源入射矢量的第四个参数可用于设置部分光源的焦距。 \
cfg.srcpos = [gridX/2, gridY/2, 60, 1]; %[control:editfield:232d]{"position":[14,39]}
cfg.srcdir = [0 0 1];                   % 光源入射矢量 %[control:editfield:6261]{"position":[14,21]}
cfg.srctype = 'pencil';                  % 光源类型 %[control:dropdown:60d7]{"position":[15,23]}
cfg.srcparam1 = [0,0,0,0];                % 光源参数1 %[control:editfield:1ab5]{"position":[17,26]}
cfg.srcparam2 = [0,0,0,0];                % 光源参数2 %[control:editfield:8fb9]{"position":[17,26]}
%%
%[text] %[text:anchor:5607] ### Step1\.2: 检测器设置
%[text] - 环积分检测器（计算量大，占用高，最准确，需要dpx）：将皮肤上的空气层作为检测器，所有经过该层的光子都会被捕获。仿真完成后，需要根据光子被捕获的位置计算各检测器的光密度。
%[text] - 密集球形检测器（计算量适中，占用适中，需要dpx）：通过在环内大量堆叠小的球形检测器，达到环形检测器的效果。仿真完成后，需要根据光子被捕获的位置计算各检测器的光密度。
%[text] - 重叠检测器（初始化时间较长，仅在2024\.11月份编译的版本中可以使用）：利用MCX中检测器重叠的特性，检测器半径为负数的检测器捕获光子，但不记录到内存中，因此仿真结果非常接近环积分检测器。
%[text] -  优化重叠检测器：牺牲内存占用优化重叠检测器的渲染速度 \
detectorType = "ring";                 % 设置检测器类型 %[control:dropdown:69ec]{"position":[16,22]}
SDSWidth = 0.2;                     % SDS环宽 %[control:editfield:33fc]{"position":[12,15]}
SDS = [1.7, 2.0, 2.3, 2.6, 2.9];                          % SDS位置 %[control:editfield:4379]{"position":[7,32]}
isusefakeSDS = true;                                  % 使能后会优化重叠球方法 %[control:checkbox:8d5c]{"position":[16,20]}

cfg.issavedet = double(true);                         % 记录光子路径长度 %[control:checkbox:1a14]{"position":[24,28]}
% cfg.issaveref = true;                                %
cfg.savedetflag = 'dpx';              % 检测器保存类型 %[control:editfield:3c18]{"position":[19,24]}
cfg.isnormalized = double(true);                      % 是否归一化 %[control:checkbox:0a18]{"position":[27,31]}
cfg.isspecular = double(true);                        % 如果光源在外部，则计算镜面反射 %[control:checkbox:9275]{"position":[25,29]}
cfg.maxdetphoton = 1e7;             % 最大探测光子数 %[control:editfield:6829]{"position":[20,23]}
cfg.minenergy = 1e-5;                % 光子轮盘赌阈值 %[control:editfield:94a5]{"position":[17,21]}
arcStep = 0.05;                      % 密集球形检测器密度 %[control:editfield:0b85]{"position":[11,15]}
detSetNum = 1;                    % 单点检测器设置个数 %[control:editfield:1779]{"position":[13,14]}

detectorRadius = SDSWidth/2/cfg.unitinmm;
detectorHeight = 0;
numPerRing = 1;

if isusefakeSDS
    fakeSDS = [min(SDS), max(SDS)]; 
end

cfg.detpos = [];
switch detectorType
    case "single"
        % 使用单点检测器
        cfg.bc = 'rrrrrr000000';
        idNums = length(SDS);
        cfg.detpos = setMCXDetPos(cfg, SDS, detectorRadius, detectorHeight, 'num', detSetNum);
        absorbanceWritePath = sprintf("%s/%s",savedataPath,ballFilePath);

    case "ring"
        % 使用环形检测器
        cfg.bc = 'rrrrrr001000'; 
        idNums = length(SDS);
        absorbanceWritePath = sprintf("%s/%s",savedataPath,ringFilePath);

    case "sphere"
        [cfg.detpos,detNum] = setMCXDetPos(cfg, SDS, detectorRadius, detectorHeight, 'arcStep', arcStep);
        cfg.bc = 'rrrrrr000000';
        idNums = length(SDS);
        absorbanceWritePath = sprintf("%s/%s",savedataPath,ballFilePath);

    case "overlap"
        if ~isusefakeSDS
            for i = 0:length(SDS) - 1
                cfg.detpos(2*i + 1,:) = [gridX/2, gridY/2, detectorHeight, -(SDS(i + 1) - SDSWidth/2)/cfg.unitinmm];
                cfg.detpos(2*i + 2,:) = [gridX/2, gridY/2, detectorHeight, (SDS(i + 1) + SDSWidth/2)/cfg.unitinmm];
            end

            idNums = length(cfg.detpos);
        else
            % cfg.detpos(1, :) = [gridX/2, gridY/2, detectorHeight, -(fakeSDS(1) - SDSWidth/2)/cfg.unitinmm + 1];
            cfg.detpos(1, :) = [gridX/2, gridY/2, detectorHeight, -(fakeSDS(1) - SDSWidth/2)/cfg.unitinmm ];
            cfg.detpos(2, :) = [gridX/2, gridY/2, detectorHeight, (fakeSDS(2) + SDSWidth/2)/cfg.unitinmm ];

            idNums = length(SDS);
        end
        cfg.bc = 'rrrrrr000000';
        
        % idNums = length(SDS);
        absorbanceWritePath = sprintf("%s/%s",savedataPath,overFilePath);
        
    otherwise
        error('检测器设置类型错误!')
end
%%
%[text] %[text:anchor:56a9] ### Step1\.3: 配置时域信息和GPU
cfg.tstart=0;                                        % starting time of the simulation (in seconds)
cfg.tend=1e-8;                                       % time-gate width of the simulation (in seconds)
cfg.tstep=1e-8;                                      % ending time of the simulation (in second)
cfg.autopilot=1;                                     % 自动配置线程
cfg.gpuid=1;                                         % 调用第一块GPU
% cfg.debuglevel='P';                                % 显示进度条
%%
%[text] %[text:anchor:7904] ### Step1\.4: 计算光子最大穿透深度（可选）
%[text] - 是否使用replay对探测器捕获的光子进行重放
%[text] - replayThresh用于滤除能量低于阈值的光子
%[text] - isjacobian用于导出Jacobian矩阵
%[text] - isAngle用于导出被检测光子的出射角度 \
%[text]     **jacobianOutputType: 导出Jacobian的类型**
%[text] 1. 光程：各个体素中累加的总光程
%[text] 2. 能量 x 光程（ua雅可比）：各个体素中累加的能量×光程
%[text] 3. 能量 x 散射（用于计算us雅可比）：加权的散射次数 \
isAngle = false; %[control:checkbox:6356]{"position":[11,16]}
isjacobian = false; %[control:checkbox:3f15]{"position":[14,19]}
jacobianOutputType = 'wl'; %[control:dropdown:2113]{"position":[22,26]}
isSlice = true;     % 是否对jacobian的结果进行切片 %[control:checkbox:96cd]{"position":[11,15]}

isreplay = false;    % 是否进行replay %[control:checkbox:00c7]{"position":[12,17]}
isppath = false;     % 是否导出各光子的光程 %[control:checkbox:3626]{"position":[11,16]}
isphotonnum = false; %[control:checkbox:6ffb]{"position":[15,20]}
replayThresh = 0; %[control:spinner:642d]{"position":[16,17]}
%[text] %[text:anchor:5a1c] ### Step1\.5: 验证模型（可选）
ispreview = false; %[control:checkbox:14ed]{"position":[13,18]}
if ispreview
    figure, 
    mcxpreview(cfg);
    set(gca, 'ZDir','reverse')
    xlabel('x direction');
    ylabel('y direction');
    zlabel('z direction');
    title('domain preview');
end
%%
%[text] %[text:anchor:3ab6] ## Step2: 读取皮肤光学参数
%[text] %[text:anchor:461b] ### Step2\.0: 读取光学参数
%[text] 设置控制带宽后，程序会读取excel中的倒数第二列作为不同波长的光子数。
excelFileName = "D:\CJY\光子计数\test.xlsx"; %[control:filebrowser:0607]{"position":[17,40]}
opticalSheet = "光学参数"; %[control:editfield:5a46]{"position":[16,22]}
isusebandwidth = false; %[control:checkbox:2d45]{"position":[18,23]}
isuseresponse = false; %[control:checkbox:5abd]{"position":[17,22]}

if isusebandwidth
    [ua, us, g, n, wavelength, nphotons] = readOpticalProperties(excelFileName, opticalSheet);
else
    [ua, us, g, n, wavelength] = readOpticalProperties(excelFileName, opticalSheet);
end
%[text] %[text:anchor:13b0] ### Step2\.1 读取皮肤模型参数
%[text] 从excel中读取各层的参数，关闭下面的开关，则使用上面构建的模型
isuseModelInExcel = false;                             % 使用excel中的模型 %[control:checkbox:5935]{"position":[21,26]}
modelSheetName = "模型参数";               % excel中模型的Sheet %[control:editfield:8b62]{"position":[18,24]}
modelNum = 1;                                       
if isuseModelInExcel
    modelData = readmatrix(excelFileName, "Sheet", modelSheetName);
    modelNum = size(modelData, 1);
end
%[text] %[text:anchor:2b77] ### Step2\.2 设置传感器的响应曲线
%[text] 传感器的相应曲线
responseWave = [];
if isuseresponse
    responseWave = [800	827.027	848.649	875.676	891.892	908.108	918.919	924.324	924.324	929.73	940.541	945.946	956.757	978.378	1000	1032.43	1059.46	1086.49	1118.92	1151.35	1178.38	1205.41	1237.84	1270.27	1308.11	1345.95	1378.38	1416.22	1454.05	1481.08	1524.32	1556.76	1594.59	1632.43	1648.65	1659.46	1664.86	1664.86	1670.27	1670.27	1675.68	1675.68	1675.68	1681.08	1686.49	1691.89	1697.3	1713.51	1729.73	1751.35	1778.38	1800;
        0.0617143	0.0821004	0.109381	0.129767	0.163941	0.204973	0.246042	0.342005	0.294005	0.403682	0.458465	0.506428	0.540639	0.574777	0.602057	0.63612	0.670221	0.697464	0.731527	0.758734	0.792834	0.820077	0.854141	0.895061	0.929087	0.956256	0.976605	1.00377	1.01723	1.03762	1.05103	1.05081	1.05055	1.03658	1.00904	0.967821	0.919784	0.858069	0.796318	0.727747	0.576853	0.508281	0.652281	0.439673	0.35735	0.275027	0.199561	0.130879	0.0621961	0.0277622	0.00700541	0.00685714
        ]';
    % 将数据分为两列
    tmp1 = responseWave(:, 1);
    values = responseWave(:, 2);
    
    % 去除重复的波长行
    [unique_wavelengths, unique_idx] = unique(tmp1, 'stable');
    unique_values = values(unique_idx);
    
    % 输出去重后的数据
    responseWave = [unique_wavelengths, unique_values];
    figure, plot(responseWave(:,1), responseWave(:,2), 'LineWidth', 1)
    xlabel('波长 (nm)'), ylabel('A/W'), title('传感器响应曲线')
end
%[text] 估计需要计算的仿真个数
fprintf("预计需要仿真%d组数据, 光学参数%d组, 模型%d组", nIter * modelNum, nIter, modelNum) %[output:6dc35d65]
%%
%[text] %[text:anchor:0816] ## Step3: 循环执行Monte Carlo仿真
%[text] 创建进度条，并创建多进程处理数据
%[text] 可通过该开关控制是否开启并行。
%[text] 在大光子模拟中，由于数据处理需要占用的内存较多，推荐关闭该功能，避免程序出现崩溃。
isuseParfeval = false; %[control:checkbox:7623]{"position":[17,22]}
h = waitbar(0, "开始仿真...", 'Name', 'Matlab程序运行中'); %[output:5cd7c6d5]
startTime = tic;

parHandleArray = parallel.FevalFuture.empty;
maxParallelTasks = 1; % 根据硬件条件调整任务数
taskIndexMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any'); % 存储任务索引
%[text] 一次读取一个仿真的参数，进行模拟
totalNum = nIter*modelNum;
energy = zeros(idNums, totalNum);
absorbance = zeros(idNums, totalNum);
detPath = zeros(size(ua,2), idNums, totalNum);
% ringphotonDensity = zeros(length(SDS), totalNum);
% ringphotonEnergy = zeros(length(SDS), totalNum);
numVoxels = zeros(length(SDS), totalNum);
detpSize = zeros(1, totalNum);

depthWritePath = sprintf("%s/%s", savedataPath, depthFilePath);
fluxWritePath = sprintf("%s/%s", savedataPath, fluxFilePath);
replayWritePath = sprintf("%s/%s",savedataPath,depthFilePath);

disp(mcxlab('version')) %[output:2ef604ef]
%%
for j = 1:modelNum %[output:group:300b9c03]
    % 创建模型
    if isuseModelInExcel
        layers = modelData(j, :)./cfg.unitinmm;
        [cfg.shapes, cfg.vol] = makeSkinWithMask(cfg.vol, layers);
    end

    for i = 1:step:nIter*step
        index = i + (j - 1)*nIter;
        fprintf("\n第%d次仿真\n波长:%s nm  模型:%d \n", index, num2str(wavelength(i)), j); %[output:92ee24c9] %[output:25da1df6]
        
        % 设置层的参数   [mua,mus,g,n]
        prop = [ua(index,:);us(index,:);g(index,:);n(index,:)]';
        cfg.prop = [0 0 1 1; prop];
        cfg.prop(1:size(cfg.prop,1), 1:2) = cfg.prop(1:size(cfg.prop,1), 1:2) / 10;  % cm-1 -> mm-1
    
        if isusebandwidth
            cfg.nphoton = nphotons(i);
        end
    
        % Simulation
        [flux, detp, ~, seeds] = mcxlab(cfg); %[output:440aa63b] %[output:20e750ef]
        
        try
            detpSize(index) = numel(detp.detid);
        catch 
            % 出现报错后继续运行下一次仿真
            errordlg(['波长: ' num2str(wavelength(i)) '模型' num2str(j) '仿真出错'])
            continue;
        end
        
        % 保存每次模拟的结果
        if issave
            % savejd('', f, 'filename', sprintf("%s/%d-f",savedataPath,excel_data.parameterwave(i)), 'compression', 'zlib');
            savejd('', detp, 'filename', sprintf("%s/%d-detp",savedataPath,opticalProperties.parameterwave(i)), 'compression', 'zlib');
        end
        
        % 根据开关变量决定使用 parfeval 还是直接获取结果
        if isuseParfeval
            if length(parHandleArray) < maxParallelTasks
                parHandle = parfeval(@exportMCX, 3, ...
                    cfg, detp, detectorType, absorbanceWritePath, ...
                    idNums, SDS, SDSWidth, responseWave, wavelength(i), ...
                    isusefakeSDS, isuseresponse, isAngle);
                parHandleArray(end+1) = parHandle;
                taskIndexMap(parHandle.ID) = index; % 记录任务的 index
            end
        else
            % 直接执行任务并获取结果
            [energy(:,index), absorbance(:,index), detPath(:,:,index)] = exportMCX(...
                cfg, detp, detectorType, absorbanceWritePath, ...
                idNums, SDS, SDSWidth, responseWave, wavelength(i), ...
                isusefakeSDS, isuseresponse, isAngle);
        end
        
        % 考虑导出Jacobian矩阵
        if isjacobian
            if strcmp(detectorType, 'single')
                exportJacobian(cfg, detp, seeds, gridX/2, ...
                    sprintf("%s/%g", savedataPath, wavelength(i)), ...
                    'outputtype' ,jacobianOutputType, ...
                    'isSlice', isSlice);
            else
                exportJacobian(cfg, detp, seeds, gridX/2, ...
                    sprintf("%s/%g", savedataPath, wavelength(i)), ...
                    'SDS', SDS, 'width', SDSWidth, ...
                    'outputtype' ,jacobianOutputType, ...
                    'isSlice', isSlice);
            end
        end

        % 考虑光子计数
        if isphotonnum
            if strcmp(detectorType, 'single')
                exportPhotonPath(cfg, detp, seeds, gridX/2, ...
                    sprintf("%s/%g", savedataPath, wavelength(i)), ...
                    'numWorkers', 4);
            else
                exportPhotonPath(cfg, detp, seeds, gridX/2, ...
                    sprintf("%s/%g", savedataPath, wavelength(i)), ...
                    'SDS', SDS, 'width', SDSWidth, 'numWorkers', 4);
            end
        end
        
        % 考虑导出穿透深度
        if isreplay
            if strcmp(detectorType, 'single')
                [photonMaximumDepth, photonMeanDepth, photonPPath] = exportDepth2(cfg, seeds, detp, replayThresh, ...
                    'isppath', isppath);
            else
                [photonMaximumDepth, photonMeanDepth, photonPPath] = exportDepth2(cfg, seeds, detp, replayThresh, ...
                    'SDS', SDS, 'width', SDSWidth, 'isppath', isppath);
            end

            writematrix(photonMeanDepth, depthWritePath,'WriteMode', 'append', 'Sheet', '加权穿透深度')
            writetable(photonMaximumDepth, depthWritePath,'WriteMode', 'append', 'Sheet', strcat('穿透深度-',string(ceil(i/step))))
            writetable(photonPPath, depthWritePath, 'WriteMode', 'append', 'Sheet', strcat('光程-',string(ceil(i/step))))
        end

         % 检查已完成的任务并获取结果（仅在使用 parfeval 时执行）
        if isuseParfeval
            while ~isempty(parHandleArray) && length(parHandleArray) >= maxParallelTasks
                completedIdx = fetchNext(parHandleArray);
                completedID = parHandleArray(completedIdx).ID; % 获取任务 ID
                currentIndex = taskIndexMap(completedID); % 获取任务对应的 index

                % 提取结果
                [energy(:,currentIndex), absorbance(:,currentIndex), detPath(:,:,currentIndex)] = ...
                    parHandleArray(completedIdx).OutputArguments{:};

                % 移除已完成的句柄和索引
                parHandleArray(completedIdx) = [];
                remove(taskIndexMap, completedID);
            end
        end        
    
        elapsedTime = toc(startTime);
        estimatedTotalTime = (elapsedTime / index) * nIter * modelNum; % 估算总时间
        remainingTime = estimatedTotalTime - elapsedTime; % 剩余时间
    
        % 更新 waitbar 显示
        waitbar( index/nIter/modelNum, h,... %[output:1c478d5c]
            sprintf('运行波长: %d\n运行模型: %d\n进度: %.2f%%\n估计剩余时间: %.2f秒',... %[output:1c478d5c]
            wavelength(i), j, index / nIter/modelNum * 100, remainingTime)); %[output:1c478d5c]
    end
end %[output:group:300b9c03]
%[text] 确保最后未完成任务也处理完
while ~isempty(parHandleArray)
    completedIdx = fetchNext(parHandleArray);
    completedID = parHandleArray(completedIdx).ID;
    currentIndex = taskIndexMap(completedID);

    [energy(:,currentIndex), absorbance(:,currentIndex), detPath(:,:,currentIndex)] = ...
        parHandleArray(completedIdx).OutputArguments{:};

    parHandleArray(completedIdx) = [];
    remove(taskIndexMap, completedID);
end
%%
%[text] %[text:anchor:4682] ### 计算光密度
energy = energy(energy(:,1)~=0,:);
S = pi*((SDS + SDSWidth/2).^2 - (SDS - SDSWidth/2).^2);
density = energy ./ S' / cfg.nphoton / cfg.respin;

writematrix(density', absorbanceWritePath, 'Sheet','光密度');
writematrix(detpSize, absorbanceWritePath, 'Sheet','检测器检测光子数');

if strcmp(detectorType, "overlap")
    writematrix(energy, absorbanceWritePath, 'Sheet', '光能量');
end
%%
%[text] %[text:anchor:255c] ### 绘制图像
%[text] 启动图像绘制后，会自动将光密度的光谱和衰减曲线绘制
if isplot
    wavelength = [1050, 1219, 1314, 1409, 1550, 1609];
    figure , 
    tiledlayout(3,1,'TileSpacing', 'tight')
    
    % 绘制光密度
    nexttile, plot(SDS, density, '-o', 'LineWidth', 1), legend(num2str(wavelength'))
    xlabel('SDS (mm)'), ylabel('photon density'), title('photon density')
    
    nexttile, plot(wavelength, density', '-o', 'LineWidth', 1), legend(num2str(SDS'))
    xlabel('wavelength (nm)'), ylabel('photon density'), title('spectrum')
    nexttile, mcxplotshapes(cfg.shapes, [gridX, gridY, gridZ]);
end
%%
figure,  %[output:843b74c1]
mcxplotshapes(cfg.shapes); %[output:843b74c1]
hold on  %[output:843b74c1]
set(gca, 'ZDir', 'reverse') %[output:843b74c1]
plotmesh(detp.p,'r.') %[output:843b74c1]
hold off %[output:843b74c1]
%%
%[text] %[text:anchor:774e] ### 保存模拟设置
%[text] 将模拟中的设置保存为pdf，存在一些问题，可能需要在运行后摁ctrl \+ s
% matlab.internal.liveeditor.openAndConvert ('MCX_Skin7.mlx', [char(savedataPath) '/log.pdf'], 'HideCode', false);
export('MCX_Skin7.mlx', [char(savedataPath) '/log.pdf'], 'HideCode', false);

%[appendix]
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":13.8}
%---
%[control:editfield:634c]
%   data: {"defaultValue":0,"label":"仿真步长","run":"Section","valueType":"Double"}
%---
%[control:editfield:6e4a]
%   data: {"defaultValue":0,"label":"总仿真次数","run":"Section","valueType":"Double"}
%---
%[control:editfield:3273]
%   data: {"defaultValue":0,"label":"单次模拟重复次数","run":"Section","valueType":"Double"}
%---
%[control:editfield:04d6]
%   data: {"defaultValue":0,"label":"网格单位(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:6a1c]
%   data: {"defaultValue":"\"623F9A9E\"","label":"随机种子（十六进制）","run":"Section","valueType":"String"}
%---
%[control:editfield:8d20]
%   data: {"defaultValue":"1e7","label":"光子数","run":"Section","valueType":"MATLAB code"}
%---
%[control:dropdown:0474]
%   data: {"defaultValue":"'flux'","itemLabels":["光强","光能量","光程"],"items":["'flux'","'energy'","'length'"],"label":"输出类型","run":"Section"}
%---
%[control:checkbox:73cf]
%   data: {"defaultValue":false,"label":"是否保存","run":"Section"}
%---
%[control:checkbox:0bb6]
%   data: {"defaultValue":false,"label":"是否绘图","run":"Section"}
%---
%[control:checkbox:87ed]
%   data: {"defaultValue":true,"label":"模型原点是否从0开始","run":"Section"}
%---
%[control:editfield:53fc]
%   data: {"defaultValue":0,"label":"空气层(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:1862]
%   data: {"defaultValue":0,"label":"掩膜层(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:8529]
%   data: {"defaultValue":0,"label":"角质层(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:0e09]
%   data: {"defaultValue":0,"label":"活表皮(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:815d]
%   data: {"defaultValue":0,"label":"乳突真皮(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:2ca2]
%   data: {"defaultValue":0,"label":"上血网(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:28d7]
%   data: {"defaultValue":0,"label":"网状真皮(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:6132]
%   data: {"defaultValue":0,"label":"网状真皮(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:20ce]
%   data: {"defaultValue":0,"label":"网状真皮(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:8c68]
%   data: {"defaultValue":0,"label":"网状真皮(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:5968]
%   data: {"defaultValue":0,"label":"下血网(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:769b]
%   data: {"defaultValue":0,"label":"皮下脂肪层(mm)","run":"Section","valueType":"Double"}
%---
%[control:editfield:1de5]
%   data: {"defaultValue":0,"label":"模型尺寸X","run":"Section","valueType":"Double"}
%---
%[control:editfield:8993]
%   data: {"defaultValue":0,"label":"模型尺寸Y","run":"Section","valueType":"Double"}
%---
%[control:editfield:232d]
%   data: {"defaultValue":"[gridX\/2, gridY\/2, 60, 1]","label":"光源位置","run":"Section","valueType":"MATLAB code"}
%---
%[control:editfield:6261]
%   data: {"defaultValue":"[0 0 1]","label":"光源入射矢量(第四个参量可用于配置初始光子重量)","run":"Section","valueType":"MATLAB code"}
%---
%[control:dropdown:60d7]
%   data: {"defaultValue":"'pencil'","itemLabels":["'pencil'","'cone'","'disk'","'gaussian'","'zgaussian'","'planar'"],"items":["'pencil'","'cone'","'disk'","'gaussian'","'zgaussian'","'planar'"],"label":"光源类型","run":"Section"}
%---
%[control:editfield:1ab5]
%   data: {"defaultValue":" []","label":"光源参数1","run":"Section","valueType":"MATLAB code"}
%---
%[control:editfield:8fb9]
%   data: {"defaultValue":" []","label":"光源参数2","run":"Section","valueType":"MATLAB code"}
%---
%[control:dropdown:69ec]
%   data: {"defaultValue":"\"ring\"","itemLabels":["单点检测器","环积分检测器","密集球形检测器","重叠环形检测器"],"items":["\"single\"","\"ring\"","\"sphere\"","\"overlap\""],"label":"检测器类型","run":"Section"}
%---
%[control:editfield:33fc]
%   data: {"defaultValue":0,"label":"环形检测器环宽","run":"Section","valueType":"Double"}
%---
%[control:editfield:4379]
%   data: {"defaultValue":"[1.7,2.0,2.3,2.6,2.9]","label":"检测器位置","run":"Section","valueType":"MATLAB code"}
%---
%[control:checkbox:8d5c]
%   data: {"defaultValue":false,"label":"是否优化重叠检测器","run":"Section"}
%---
%[control:checkbox:1a14]
%   data: {"defaultValue":true,"label":"是否记录光子路径长度","run":"Section"}
%---
%[control:editfield:3c18]
%   data: {"defaultValue":"'dp'","label":"检测器保存类型","run":"Section","valueType":"Char"}
%---
%[control:checkbox:0a18]
%   data: {"defaultValue":true,"label":"是否归一化","run":"Section"}
%---
%[control:checkbox:9275]
%   data: {"defaultValue":true,"label":"是否计算镜面反射","run":"Section"}
%---
%[control:editfield:6829]
%   data: {"defaultValue":"1e7","label":"最大记录光子数（严重占用内存和显存）","run":"Section","valueType":"MATLAB code"}
%---
%[control:editfield:94a5]
%   data: {"defaultValue":"1e-7","label":"光子轮盘赌阈值","run":"Section","valueType":"MATLAB code"}
%---
%[control:editfield:0b85]
%   data: {"defaultValue":0,"label":"密集球形检测器密度","run":"Section","valueType":"Double"}
%---
%[control:editfield:1779]
%   data: {"defaultValue":0,"label":"单点检测器个数","run":"Section","valueType":"Double"}
%---
%[control:checkbox:6356]
%   data: {"defaultValue":false,"label":"是否导出角度","run":"Section"}
%---
%[control:checkbox:3f15]
%   data: {"defaultValue":false,"label":"是否导出灵敏度矩阵","run":"Section"}
%---
%[control:dropdown:2113]
%   data: {"defaultValue":"'wl'","itemLabels":["能量x光程","加权散射计数","能量"],"items":["'wl'","'wp'","'flux'"],"label":"jacobian导出选项","run":"Section"}
%---
%[control:checkbox:96cd]
%   data: {"defaultValue":true,"label":"是否切片","run":"Section"}
%---
%[control:checkbox:00c7]
%   data: {"defaultValue":false,"label":"是否导出穿透深度","run":"Section"}
%---
%[control:checkbox:3626]
%   data: {"defaultValue":false,"label":"是否导出各光子光程","run":"Section"}
%---
%[control:checkbox:6ffb]
%   data: {"defaultValue":false,"label":"是否对光子计数","run":"Section"}
%---
%[control:spinner:642d]
%   data: {"defaultValue":0,"label":"replayThresh","max":1,"min":0,"run":"Section","runOn":"ValueChanging","step":0.0001}
%---
%[control:checkbox:14ed]
%   data: {"defaultValue":false,"label":"是否preview","run":"Section"}
%---
%[control:filebrowser:0607]
%   data: {"browserType":"File","defaultValue":"\"\"","label":"光学参数Excel","run":"Section"}
%---
%[control:editfield:5a46]
%   data: {"defaultValue":"\"光学参数\"","label":"光学参数Sheet","run":"Section","valueType":"String"}
%---
%[control:checkbox:2d45]
%   data: {"defaultValue":false,"label":"是否使用带宽","run":"Section"}
%---
%[control:checkbox:5abd]
%   data: {"defaultValue":false,"label":"是否考虑传感器的相应曲线","run":"Section"}
%---
%[control:checkbox:5935]
%   data: {"defaultValue":false,"label":"是否使用excel中的模型","run":"Section"}
%---
%[control:editfield:8b62]
%   data: {"defaultValue":"\"模型\"","label":"模型Sheet","run":"Section","valueType":"String"}
%---
%[control:checkbox:7623]
%   data: {"defaultValue":false,"label":"是否使用并行处理","run":"Section"}
%---
%[output:6dc35d65]
%   data: {"dataType":"text","outputData":{"text":"预计需要仿真2组数据, 光学参数2组, 模型1组","truncated":false}}
%---
%[output:5cd7c6d5]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAXgAAAByCAIAAADWE10jAAAAB3RJTUUH6QERCSIZ5FIszwAAFZZJREFUeJzt3XtUG9edB\/DfHWGQQAgkMEIgjEGAeTm05mVexuB3bWy3cZKTbN2TZLfpepu2x9ut2\/W69uk2Jz3J6Tk5zWPrPcnGPTlJ3Y2zqVPKblxbYAN+YmMT\/BBvcEDiaYmAkEDMzP5xJTGABCTWGJv8Pn\/EM6M7984F6et774wcAgJlZWWAEEK+UF5e7t72o3+UlZURQkpKNxSt3xIRoV6kC0MILQXj9tFbjfWEEJ7nadwQACgrK1MqVT\/8yYEx8F\/sK0QILREahf\/Lvz5sNt8rLy\/3AwBCyA9\/cmCMBCz2hSGElg7TiOPgL\/\/9wE9\/BAB+ZWVla9cW2kgAWezLQggtMb0jjmee2cvzvB8AbP7WTiuPOYMQ8r2SjVs\/+OA9PwCI0UYbugcW+3oQQkuW864TjmcQQuJxBQ3BqEEIiQWDBiEkOr\/FvgCEHl5jo2PNTR1m84jPa1Yqg5NWxQXKAwHAZhvr+bxrbHTU560EyuXRMbEyWSA8qL54M8+IxtDW1T9wb4HtxWo1sdrIL3WJCD3MGm40feMxXYQ6zOc19\/cN3bjRlF+0BgC62lsTE3SqsHCft3JvaLCltTUlPQMeVF+8mS9oDM35O3ZOTrITk9yEg51wTDomuYlJboLlHPQIyzkm2YlJzmYd+eKzxpUxGp93A6HFYrePhy9XDVqsPq85fLnKbr9NP3eTDodKFT48avN5KypV+KTDQFt5MH3xZp6pU0y43HhJLzxCAAIAAgA4nud5nuecf\/I8zwXjNxjQkkIIYQgRYwVTWC1haDOMz1uhNTu3PfWFB54AAQAeXH9MO99VBACIsywPQJylncUX8iOaZ0QTvyJq+6ai2cc5jmM5jmMpjuVYluUqzlSL8Cvp7ao1hRZ+M8Tzq6P99dW2Fd+K9TjqHGttrm+G2DWhA\/W9Y8IXNLGzKxy8\/tnd4KQ1CdIZNdyVJyVH0oamVzKjHnqdGktt\/bDXMk72z2v6ZEWerxk9bBiGML6PAGAYcH3uCGGI91aqz5ypO3\/BWzXZBfnrNm709iphnBnmbpQQ4k4VACBAAHgeyKVzZ+svXaEH1+Tm5q9fd+Fsdf3ly84ja3PziosJAZ4HhgAQnucJADC0MkFfvJknaDwe5jju3OnzCv2\/Jfz0BBMYRFOG4zgys57RvvpzvdbgyMx16mnrRL1dNdcsQauS1yQs4OtVhFbrpRMECMzO0\/HPqw2dIwCalUXbQ2C0b1CzsmjNVCLUGOkZw4aKzmkPKpqaa5un9oJWJa9JXCmvvjukiQ0PVmdun+Nb7cOGepKyPZRAaNH2ebvEeLpm9BCiwwyJCEHD0Hc1oR9X2ornN0Td+Qsv\/Wq\/t3oOHXmtZPOmOVpxDzdoXwghrpSh\/+UJMDzw9ZeufPTf\/0nP2vPUDwgh9ZcvC48UrF8PU4EgePeSaX3x5kvf3uY4rsdi+9tb7+w\/MNL7yQn1U3tpyrAsOysQCABIg8AyZI0MkruP2u82W+ZpdbT32ll77I6V4a565gga8JBD0hXF31hh6qw2ASEEyKwapnZDU92teLEiU3rt+vDyNaHei1ju\/LU3aH3y8jl+hqbO6muWaUcqBLtRK9fNVT9aTOL8jeD+8AMAYeZ4hy+gqjlfo\/Ml5x5DCMMAzwMdnADQQQkBkpm3ds9TP\/jw+O8B4MPjv3\/y6X0fHv89x3EA8OTT+zLz1hKGodMoAoJZFg88OGdnCwoaxkshnp02aeM4rslo+ef3LuzpusJIZCPnT4bv+TuaMhzHchw\/ox4CIFsebetsHo7NVDqPjQwPEM3KKNMAYbzPSonzRwTuEc0CSrqNmK6eNVkBACzVRunKLCUYO6uNggJRSme6AwEybCjv6J9Vb1ByalaiFAAgOCor03yn\/MbsMgAQkZUa2NwbtD41Nth855w9tljj+R4fIVMVgr3rnCmwOG65+2qbRZmgI18ggomGD9F1D\/fnxfVOn8uhI68Jd6eGOXOdSGD6p1tCCM0KcCUGDwSALyotJYQ8+fS+4++\/CQDH33+TZVkAePq7L2bl5xWWlAAAAAOEF5zlnHpR3jKEco1ovAzbOMJObXPcX6pv\/ub9s5FNtVopC22T0uEei8EQpNPRqCHATq+HEACQJ0VF\/MV0d5VqZTAAwECzCaJS5V+YBlyXZm2+fcVAF9yV6Tvjl5vaq+rMAHC73ByUnJoTTC\/PU0lXE0xvx7k689RxRVTOzqiBq9duGiEiOy1OA3E7o7z\/ElRpO1VpIzZrsCwIAEZMV6qMkJyakyQDMN\/6S3s\/QER2ZtpOVRoAmNqrmmQ56zVBwmqi0gBsnWd7gzI1XeX1s\/MoIjszbdbbaiplCXF3ED1sCCGMhJFIPL5Yo9fXXfC+epKfX7Rhg7dXGcLQ5VlwrdEwjOdWhP71pV\/Tjd8c+uVUVd5PZOgaDeMe+DPuOQ4PPLiWdQkwwPPrSjcQgKe\/++J\/vOFs5Z9+9Mvs\/LzCDaXgChcyPXOdczBBX7yZZ+rE8xwAsDx\/vXv0TKPp9JVOWW9rXPeN0FgGDJNyBfSe+j\/ZP+5jWY5lWZaH2VMnAKKKiG6\/2WyJy1LCiLHDqIzLDoSrzo7DiLEL4kt3yQCg\/+rVm9cspVm60lLj5Upb3C5dBACYnBNATyWVQADAfNOoK92lm3YczNZRGUQrg4ymTqOxo2dGv2RxpWlxwYQoZEGEEACr1XSrymwFAEVU7q4sV46o0neprE23Op2\/G1tHkz0uSycn5luf3FtOLw8AAKxNHR3BUaUKJexSuY7ZOqraISstLhiA9mJqhuf6tbt\/Srhi80iqu3DBvYox256nfjBH0FBf9tcuzJeFW2ArNZX6ugsXX\/vtofHxcXrktd8e2v8vL\/EARRtK77OV+YKGJQDwh+rW\/+1gJQ57hFwKQ+2xMCGXy2ASZKHEer5y8vl\/4AA4juM4fkbQEDpFXJ4c3ak3diar5E1GkpKuJmTAvXykiE5X2Doqr7Z\/AQAA0fQk54nO0RmtyWtJ1WPZKtqsOjm6U28ezFYtN9pJtAy+kMVHm29C9oZsALB1VLZBdrrzk+9k76y62veF4MAXxsufOGdZ6pzs9CiYmksbTQPRulwFAVCl55j1V80bslUAYG26edlgc16PsPMgXD0iVsOtSoPg9U+uTm1H6zBoHlZz\/2La2tq+ar20csHUaT5zLAl7b2Xm6glhGEKA590N8wQIAf5cZWXdhYuvvHxgYmICAH5+8NVXXj4AAK+8fODnB19lCFm3cSMPPKErM4ROoUCw1nN\/QUPvYj+5JlLmaPpbJ89Wf5TQ81lKmEyhApAwfVHpy1rvDl66GJqTy7Ic8JyHzxoQQhTR8dqedqNprEemTgl0rXszhBCrofHiHdBtzNkYDFZD48URhsbHtIsiCy9Jd8c7jUQdBe0jDIlOWN3Teuak6+lmfV07ACi0eRuigkbGrYqwtdkJq13X2193pT8qJz0aAMw3\/zwUEe28UgKEEHuHMXB1diAB880\/t\/QCANy7FR2WHm3u7AnLyxm7aGSmd56ZHjQgT3lsbbJzjaZD3x20IcE5IBoxXjIwGDQPJULXPL3\/bhwOxzzne3+FTC0Jg+uuxVe7SK8nEroQKXhzMQzDO9+cziJ0CYre26LdOXTktZzCgp8ffJVG20u\/2n\/oyGvrNm1iXE251oNpBe7P3n0EDQs8y3H+\/v678lKyYnp6QzYFjtdoEiT+Uq4z7bmQnN22fONgpT44M5vjWHbmiMZZMyEA6uiwzy53j2oTNylcV0kIIWRsxCZPzYhXEAB7v9EGwe5LmborR3e8l7zXbyTqaACwt9d1j2oT1cTWrgiTE5uzY9rETVoAsLfrmyH7sXiF69JGbKAIm5b2zmbBaugeTU1aLXwXGHvauofaursBwjK+k7saAOBeo944po1evRGgp3XWD5G4h2IAANrEvGkvCSZLiui8nDl+Q2hxSQjj7fZ2TmHBjAXaGa\/OcV+cIVPPnjD0cReJ58L5xevmaCW\/eJ23E4GuBLqmBgRAwjCEYYjzXhEAAM87l1ZyBX3JLSwo3ryZkKnl59yiQrrSwxOe8ARcwxgCBAhIGIbcZ9Dwk3T1heU4PiJSrQwrtfP\/o+Aa29jvhBc8AQDLY2Jkj+9xLgZ7HdEAgFabYBga1YZNu8tMiDolpu10w+nbABAYqQ10ftBDwiJDGho+HpKnZuQraEEvJQkBCIOey6fpk0XapM25KgDQpQD0wLQRBbifuaF7tnaDLTJHNrPjhBAC8pSMfAAAsN757MJtG0CjfNNjmx9PnF407DH3g1IzRi8empveyBw\/cvQQmbaqNkvxxk3FG70+w7KQyl1\/l871YNWGbds2bNt2X20IJlAMHaUT9+vOB31LtmxZv2WL+wp4gJLNW0o2bxFWxgMwM6Z8s\/rizXxTJ+CEz\/4CgDXuGdNAS1jyd4A+H8xyAQEB9FEajp8xognRFuxx7wTqNk39pR65Ni9yqozWfTxDUFjn3E7aovVe0tVEBsxCQ3a05\/ypz6e+Fnv6UisAAMhjwkARUxBCL3es7XRD6zAABCakCbtwr60nrHBPRhDca\/jo0t88\/YAi8\/Iyoqcv6PY0n7o4BAAQElMY4v2Hj0HzaGAYRuLlrtN9VgvuDz\/DSCSitCKRMAwzNS8XbrvSc2pqyADhXd9BcM2Q6L1vOiDieULoI8EEnM\/T0JENc\/9PBgNP3ClDn5dRaLODNJl03\/kfmjIcO2+qPVjaVVu1ABBW+ETMfEWDEjbnJ3g4HvaNzWHOjSfyF9CWa\/uJeZtbNd8loYcBIYQwjMT73OSr18xM3WmmX3RiRHj+2DVzco24nUEzFTGuNUie8IQH3vnMBR3luCNIuGI9fYxHCMMDL+yLN\/MEjTw07PjHf11gr5Thyx+moEHofgUGSgf6hzSaiPmLfkkmU39goJR+XgICpMMWi1KlnPesL8t8zxwQ4GzlwfTFG\/e\/Gey5UFxCclxCss+vDKFHQu7ab166eN1mu+HzmmUy6dq8b9LPnS5xVUtLk2NiwuetLPP31yWuoq08mL54g\/+UJ0JeBSuCNm0pFLuVgABparqHVUbfejB98cb179FgziCERDPP1AkhhO6fH8\/zHl\/QyLkHfCkIoUedadTDvTOe5\/EfJ0AIiQ6DBiEkOgwahJDoMGgQQqLDoEEIiQ6DBiEkOgwahJDoMGgQQqLDoEEIiQ6DBiEkOgwahJDoMGgQQqLDoEEIiQ6DBiEkOgwahJDoMGgQQqLDoEEIiQ6DBiEkOgwahJDoMGgQQqLDoPnaYVlWuMtxXE1NjfDIiRMnPJ5ot9utVivdbmhomLeht99+2+FwfNXLREsKBs3S1NLSUllZWVVVVVFRUeVy8uTJqqqqvXv3njp1yl2yo6Pj448\/Fu7q9XqPAaHX6w8fPky3u7u7jx07NqMAy7IOgWvXrgEA3T5x4kR3d7fv+4keEX7zF0GPoMTExMTERAD48Y9\/\/Prrr9OD27dvr6ioKCkpEZZsaWnZunWre7eiouJnP\/vZ6OioXC5ftmyZsGR5efmRI0fo9rZt2z766CO6fefOnZSUFAAwm80Gg4Ge5XA4JBJJfX09LbNixYrx8XExeooeCTii+fqyWq2nTp2qqKiw2Wx\/+tOf\/vjHP1osFj8\/P51Op1Qq33jjjY6ODnfhlpaW5OTk\/v7+hoaGtra2N998Mzc3t6ur69atW01NTXQEFB4eXlhYODY2NjExMTEx4e\/v73A4BgcHOzo6cnNzdTrd4vUVLTIc0Xx9BQUFbdmy5ezZs7t37\/700085jnvnnXeKioouX748OTm5atWq559\/\/syZMxKJBADefvttlmUzMjIAwGazDQwMxMbG0nrS0tKE1dbU1OzYsWPNmjWlpaUAUFtba7fbH3jn0MMFg2YJMpvNN27coFMYs9lcW1tLj9vt9tra2r6+vg8\/\/PDo0aNKpdJisWg0GgCor69\/7rnnampq7t69Gx8fn5GRIZVKTSYTPbGysnLXrl16vZ7uWiyWyclJ+uqxY8deeOGF8PBwd+sMwzQ0NIyNjdHdmzdvRkZGPqiuo4cUBs0SpFQqi4uLGYYBgOPHjxcWFtLjUqmUbj\/++OP0yKVLlwoKCgCgv79fo9Hs378\/IiKCvjQ0NPTtb39bIpH09fWFhITodDp30HR2dsbGxtKEunbtmjBlAMDPD99UaCZ8TyxNNGUAYO5py5UrVw4fPjw0NBQaGgoAdXV1bW1tq1evBoDGxkaZTPb9739frVar1WqLxeI+a3h4OCkpiW7L5fLZ1SYmJqanp9Ntq9Vqs9l80Sf0CMOgWcq6uroyMzPnKLB3794PPvjg+vXrZWVlAODn57d69Wr3bamJiQmPZ9XW1h44cAAAHA6HSqVa4MW4b06hryEMmqXsxIkTzz777BwF4uLiIiMj6+vr33vvvQVGxtDQkFQqVSgUAHD37l33iMbhcOj1+oCAALVabTAYBgcHQ0JChoeHBwcH5XL5p59+euPGjeDgYK1WCwCNjY0RERFqtVq4LTyIlhi8vb1kVVZWFhQUzFhAme31118\/ePDgK6+80tjYyPN8Y2MjfbqvsbFRWMz9FMyxY8defPFFu93OcVx7e3tycjI9vmzZsq1bt5aUlJSWljY0NOh0upKSkt27d8fHx7e2tiYmJv7iF7+gKQMAb7311sWLF2dsCw+iJQZHNEvT+fPnY2Ji6DN7bv7+\/sJdlmXLy8tfeOEFpVIJAM8880xFRUVmZiZdHvbz8wsMDHQX7unp8fPzq6io+N73vhcaGupwOI4ePXry5Ml3331XWGdlZeXQ0NDvfvc79yJRaWlpUlLSvn37ysvL3cWOHj06e1t4EC0xZMeOHf\/1h+P37PyMFzRyblEuCN2\/8fHxZcuWuT\/qbhzHCQ\/a7XapVLrwOuntJPpYjftgQECAe3dwcFCpVAoLuPX19eGc6OvANDrzXaeSkr9\/9mkc0SxBwg+\/0IzoWXjKeKtzxsE5pmmYMl9zuEaDEBIdBg1CSHQ+njpdvXrVtxUihBZFVlaWD2vz\/RpNamqqz+tECD1It2\/f9m2FOHVCCIkOgwYhJDoMGoSQ6DBoEEKiw6BBCIkOgwYhJDoMGoSQ6DBoEEKiw6BBCIkOgwYhJDoMGoSQ6Hz\/XSeff0sCIfSo83HQ+PYbnwihpQGnTggh0WHQIIREh0GDEBIdBg1CSHQYNAgh0WHQIIREh0GDEBIdBg1CSHQYNAgh0WHQIIREh0GDEBIdBg1CSHQYNAgh0WHQIIREh0GDEBIdBg1CSHQYNAgh0WHQIIREh0GDEBIdBg1CSHQYNAgh0WHQIIREh0GDEBKd1\/+vk2kUMwgh5BuYJggh0WHQIIREh0GDEBIdBg1CSHQYNAgh0TnvOqmkZHGvAyG0hJEdO3Ys9jUghJa4\/wfUdsq2A6xuCQAAAABJRU5ErkJggg==","height":109,"width":360}}
%---
%[output:2ef604ef]
%   data: {"dataType":"text","outputData":{"text":"v2024.6\n","truncated":false}}
%---
%[output:92ee24c9]
%   data: {"dataType":"text","outputData":{"text":"\n第1次仿真\n波长:999.9 nm  模型:1 \n","truncated":false}}
%---
%[output:440aa63b]
%   data: {"dataType":"text","outputData":{"text":"Launching MCXLAB - Monte Carlo eXtreme for MATLAB & GNU Octave ...\nRunning simulations for configuration #1 ...\nmcx.respin=1;\nmcx.unitinmm=0.01;\nmcx.seed=1648335518;\nmcx.nphoton=5e+06;\nmcx.outputtype='flux';\nmcx.issrcfrom0=1;\nmcx.dim=[800 800 815];\nmcx.mediabyte=4;\nmcx.shapedata='{\"Shapes\":[{\"Grid\": {\"Tag\":0, \"Size\":[800,800,815]}},{\"Box\": {\"Tag\":1, \"O\": [0,0,0], \"Size\": [800,800, 40]}},{\"Box\": {\"Tag\":2, \"O\": [0,0, 40], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":3, \"O\": [0,0, 60], \"Size\": [800,800, 2]}},{\"Box\": {\"Tag\":4, \"O\": [0,0, 62], \"Size\": [800,800, 5]}},{\"Box\": {\"Tag\":5, \"O\": [0,0, 67], \"Size\": [800,800, 10]}},{\"Box\": {\"Tag\":6, \"O\": [0,0, 77], \"Size\": [800,800, 8]}},{\"Box\": {\"Tag\":7, \"O\": [0,0, 85], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":8, \"O\": [0,0, 105], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":9, \"O\": [0,0, 125], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":10, \"O\": [0,0, 145], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":11, \"O\": [0,0, 165], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":12, \"O\": [0,0, 185], \"Size\": [800,800, 630]}},{\"Cylinder\": {\"Tag\":13, \"C0\": [400,400,40], \"C1\": [400,400,60], \"R\": 350}},{\"Cylinder\": {\"Tag\":14, \"C0\": [400,400,40], \"C1\": [400,400,60], \"R\": 110}}]}';\nmcx.srcpos=[400 400 60 1];\nmcx.srcdir=[0 0 1 0];\nmcx.srctype='pencil';\nmcx.srcparam1=[0 0 0 0];\nmcx.srcparam2=[0 0 0 0];\nmcx.issavedet=1;\nmcx.savedetflag=21;\nmcx.isnormalized=1;\nmcx.isspecular=1;\nmcx.maxdetphoton=1e+07;\nmcx.minenergy=1e-05;\nmcx.detnum=0;\nmcx.bc='rrrrrr001000';\nmcx.tstart=0;\nmcx.tend=1e-08;\nmcx.tstep=1e-08;\nmcx.autopilot=1;\nmcx.gpuid=1;\nmcx.medianum=15;\n###############################################################################\n#                      Monte Carlo eXtreme (MCX) -- CUDA                      #\n#          Copyright (c) 2009-2024 Qianqian Fang <q.fang at neu.edu>          #\n#                https:\/\/mcx.space\/  &  https:\/\/neurojson.io\/                 #\n#                                                                             #\n# Computational Optics & Translational Imaging (COTI) Lab- http:\/\/fanglab.org #\n#   Department of Bioengineering, Northeastern University, Boston, MA, USA    #\n###############################################################################\n#    The MCX Project is funded by the NIH\/NIGMS under grant R01-GM114365      #\n###############################################################################\n#  Open-source codes and reusable scientific data are essential for research, #\n# MCX proudly developed human-readable JSON-based data formats for easy reuse.#\n#                                                                             #\n#Please visit our free scientific data sharing portal at https:\/\/neurojson.io\/#\n# and consider sharing your public datasets in standardized JSON\/JData format #\n###############################################################################\n$Rev::188338$v2024.6 $Date::2024-11-13 00:00:36 -05$ by $Author::Qianqian Fang$\n###############################################################################\n- code name: [Jumbo Jolt] compiled by nvcc [9.2] for CUDA-arch [350] on [Nov 13 2024]\n- compiled with: RNG [xorshift128+] with Seed Length [4]\n\nGPU=1 (NVIDIA GeForce RTX 4090 D) threadph=10 extra=330560 np=5000000 nthread=466944 maxgate=1 repetition=1\ninitializing streams ...\tinit complete : 151 ms\nrequesting 5888 bytes of shared memory\nlaunching MCX simulation for time window [0.00e+00ns 1.00e+01ns] ...\nsimulation run# 1 ... \nkernel complete:  \t2542 ms\nretrieving fields ... \tdetected 818189 photons, total: 818189\ttransfer complete:\t3291 ms\nnormalizing raw data ...\tsource 1, normalization factor alpha=200000.000000\ndata normalization complete : 7353 ms\nsimulated 5000000 photons (5000000) with 466944 threads (repeat x1)\nMCX simulation speed: 2136.75 photon\/ms\ntotal simulated energy: 5000000.00\tabsorbed: 83.85088%\n(loss due to initial specular reflection is excluded in the total)\n","truncated":false}}
%---
%[output:25da1df6]
%   data: {"dataType":"text","outputData":{"text":"\n第2次仿真\n波长:1000 nm  模型:1 \n","truncated":false}}
%---
%[output:20e750ef]
%   data: {"dataType":"text","outputData":{"text":"Launching MCXLAB - Monte Carlo eXtreme for MATLAB & GNU Octave ...\nRunning simulations for configuration #1 ...\nmcx.respin=1;\nmcx.unitinmm=0.01;\nmcx.seed=1648335518;\nmcx.nphoton=5e+06;\nmcx.outputtype='flux';\nmcx.issrcfrom0=1;\nmcx.dim=[800 800 815];\nmcx.mediabyte=4;\nmcx.shapedata='{\"Shapes\":[{\"Grid\": {\"Tag\":0, \"Size\":[800,800,815]}},{\"Box\": {\"Tag\":1, \"O\": [0,0,0], \"Size\": [800,800, 40]}},{\"Box\": {\"Tag\":2, \"O\": [0,0, 40], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":3, \"O\": [0,0, 60], \"Size\": [800,800, 2]}},{\"Box\": {\"Tag\":4, \"O\": [0,0, 62], \"Size\": [800,800, 5]}},{\"Box\": {\"Tag\":5, \"O\": [0,0, 67], \"Size\": [800,800, 10]}},{\"Box\": {\"Tag\":6, \"O\": [0,0, 77], \"Size\": [800,800, 8]}},{\"Box\": {\"Tag\":7, \"O\": [0,0, 85], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":8, \"O\": [0,0, 105], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":9, \"O\": [0,0, 125], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":10, \"O\": [0,0, 145], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":11, \"O\": [0,0, 165], \"Size\": [800,800, 20]}},{\"Box\": {\"Tag\":12, \"O\": [0,0, 185], \"Size\": [800,800, 630]}},{\"Cylinder\": {\"Tag\":13, \"C0\": [400,400,40], \"C1\": [400,400,60], \"R\": 350}},{\"Cylinder\": {\"Tag\":14, \"C0\": [400,400,40], \"C1\": [400,400,60], \"R\": 110}}]}';\nmcx.srcpos=[400 400 60 1];\nmcx.srcdir=[0 0 1 0];\nmcx.srctype='pencil';\nmcx.srcparam1=[0 0 0 0];\nmcx.srcparam2=[0 0 0 0];\nmcx.issavedet=1;\nmcx.savedetflag=21;\nmcx.isnormalized=1;\nmcx.isspecular=1;\nmcx.maxdetphoton=1e+07;\nmcx.minenergy=1e-05;\nmcx.detnum=0;\nmcx.bc='rrrrrr001000';\nmcx.tstart=0;\nmcx.tend=1e-08;\nmcx.tstep=1e-08;\nmcx.autopilot=1;\nmcx.gpuid=1;\nmcx.medianum=15;\n###############################################################################\n#                      Monte Carlo eXtreme (MCX) -- CUDA                      #\n#          Copyright (c) 2009-2024 Qianqian Fang <q.fang at neu.edu>          #\n#                https:\/\/mcx.space\/  &  https:\/\/neurojson.io\/                 #\n#                                                                             #\n# Computational Optics & Translational Imaging (COTI) Lab- http:\/\/fanglab.org #\n#   Department of Bioengineering, Northeastern University, Boston, MA, USA    #\n###############################################################################\n#    The MCX Project is funded by the NIH\/NIGMS under grant R01-GM114365      #\n###############################################################################\n#  Open-source codes and reusable scientific data are essential for research, #\n# MCX proudly developed human-readable JSON-based data formats for easy reuse.#\n#                                                                             #\n#Please visit our free scientific data sharing portal at https:\/\/neurojson.io\/#\n# and consider sharing your public datasets in standardized JSON\/JData format #\n###############################################################################\n$Rev::188338$v2024.6 $Date::2024-11-13 00:00:36 -05$ by $Author::Qianqian Fang$\n###############################################################################\n- code name: [Jumbo Jolt] compiled by nvcc [9.2] for CUDA-arch [350] on [Nov 13 2024]\n- compiled with: RNG [xorshift128+] with Seed Length [4]\n\nGPU=1 (NVIDIA GeForce RTX 4090 D) threadph=10 extra=330560 np=5000000 nthread=466944 maxgate=1 repetition=1\ninitializing streams ...\tinit complete : 145 ms\nrequesting 5888 bytes of shared memory\nlaunching MCX simulation for time window [0.00e+00ns 1.00e+01ns] ...\nsimulation run# 1 ... \nkernel complete:  \t2559 ms\nretrieving fields ... \tdetected 818179 photons, total: 818179\ttransfer complete:\t3278 ms\nnormalizing raw data ...\tsource 1, normalization factor alpha=200000.000000\ndata normalization complete : 7241 ms\nsimulated 5000000 photons (5000000) with 466944 threads (repeat x1)\nMCX simulation speed: 2116.85 photon\/ms\ntotal simulated energy: 5000000.00\tabsorbed: 85.48645%\n(loss due to initial specular reflection is excluded in the total)\n","truncated":false}}
%---
%[output:1c478d5c]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAXgAAAByCAIAAADWE10jAAAAB3RJTUUH6QERCSI7MTJtKwAAHcpJREFUeJztnXlcVNf5\/59zh21gGJZBkEUQEQVxCwoqggQENeLaGBON6StNkyb+8k2\/JulLu6S11sa84iupSUytif1WTbU2i0kal7qjgKCCKJHIJgKCM8IAM8LADMu99\/fHmblcZgMjw+Lref+h95773OecMzP3wznPWS4BEUuXLgUEQZCB4MiRI8KxE\/1v6dKlhJCU1PlJjy\/09w8YooIhCPIo0GHQ\/XCjkBDC8zyVGwIAS5cu9fHxffV\/N7aDy1CXEEGQR4RAucu2rX\/QaJqPHDniBACEkFf\/d2M7cR3qgiEI8uigau367e\/\/tPHN1wDAaenSpbNnJ+qJKxnqYiEI8ohxr7Vr7drneJ53AoAFi5e18agzCIIMPClpiw4e\/MwJAMaEBJfWqYe6PAiCPLIYR52wPYMgiOMwCQ1BqUEQxFGg0CAI4nCchroACDJ8ade1l5dVaTStA+7Zx8dzwsRwd5k7AOj17Xdra9p1ugHPxV0mCx4TJpW6w2DVxRZ9tGhKK2sa1M39zC8sJDAsZPQDFRFBhjNF18umT43wD1AMuOeG+qbr18sSkmIBoOb2rcjxEb4KvwHPpbmpseLWrejJ02Cw6mKLvoSmtDxhybLubrazm+vsYju7uru6uc5urpPlumgKy3V1s53dnL6tteX7G2PHBA54NRBkqDAYOvxG+TZq2wbcs98oX4PhJn3uuru6fH397uv0A56Lr69fd1cpzWVw6mKLPrpOY\/xkyktnxSkEwBXAFYDjeZ7nec74P8\/znCeuYEAeKQghDCGOiGCK3RKGZsMMeC7Us\/HYWl144AkQAODB9F+v+00mAECMtjwAMVobzfvzEfXRohkXGpSRnmSZznEcy3EcS+FYjmVZ7tiZLAd8JfdqclTeiY95Wb+qayjM0ocuDrPa6my\/VV5YDmGx3urCe+3iC4Fhlg4br31\/x3NC7Hg3Mw93ZBOiRtOMejsx80PLGajNKbxv08aIoTa7XppkvczIcINhCDPwEgAMA6bnjhCG2M4l68yZ\/Iu5ttzEzU2Yl5Zm6yphjBomZEoIEVQFAAgQAJ4HcunC+cJLV2hi7KxZCY\/Pyz2fVXj5sjFl9qw5ycmEAM8DQwAIz\/MEABjqTFQXW\/QhNFaTOY67cPqi\/Ozvxr\/5JePuQVWG4zhi7kdXX3jhXpvn6BnzAnrFie7VZF\/VekyMih3fj+VVhLq1UQkCBCz1tKM2q7S6FSBwbFKGF+jqGwPHJsX2KEK2kt5xv\/RYda+JiqrynPKeM4+JUbGRY2VZd5oCw\/w8A2Zk2FnVfr+0kERneBPwTsros0qMtTIjwxDazJA4QGgY+qsm9HGluVj\/QeRfzP3zltdt+Xlr846UBel2chGaG7QuhBCTytB\/eQIMD3zhpStfff4JvWvV0y8TQgovXxanzH38cegRBNGvl\/Sqiy0eeHib47i7Wv2pv\/799Y2t9\/7zZcDTz1GVYVnWQhAIALh5gLapbbSHTEg13CnX9pGr7t7V84awJWP9TH7sCA1Y0SG30OTpoarqLBUQQoBYeOg59Z4k5GKD0BluV6\/dHxXrbdtEW3L0nsfjUaPsfIaq6qyr2l4px0SnQWPn2fOPDCWO+YsgPPwAQBg7v\/B+uLJ7jfaXjGcMIQwDPA+0cQJAGyUEyIw5s1c9\/fIXh\/4GAF8c+tvqNeu\/OPQ3juMAYPWa9TPmzCYMQ7tRBES9LB54MPbO+iU0jA0jnu3VaeM4rkypfeOz3FU1VxiJtPXit36rnqUqw3Esx\/FmfgiAdFSwvrr8ftgMH2Na6301CRwbpFITxnavlBg\/IhBaNP2wFGhVFZxXtQEAaLOUbmNn+oCyOkspMgjyMao7ECD3S49UNVj49YiaNDPSDQDAM2jmDE3JkeuWNgDgP3OSe\/k9j8cnhXlqSi4YwpIDrY\/xEdLjEAw1F1TuyeGjhNKWO6SDjgwERNTRGEBo3EN4Xky\/dHu8tXmH+LSnmWPvRgK9n24JIVQrwKQYPBAAPik1lRCyes36Qwc+BoBDBz5mWRYA1qz7n5kJcxJTUgAAgAHCi+4ydr0otjSEYmrR2Gi2cYTtOea477KK3zlwfnRZTogbC5XdbvfvaktLPSIiqNQQYHv7IQQAZBOC\/L9T3ZnoO9YTAEBdroKgSbIWldpUtLbym1dKacDdZ\/KycaNUtzPzNQBw84jGI2pSvCctnjVLUxbMvaoL+ZqedHlQ\/LIgdcHVYiX4x8WEB0L4siDbX4JvzDLfmFZ9m6fUAwBaVVcylRA1KX6CFEDzw3e3GwD842bELPONAQDV7cwyafzjgR5iN0ExAPrq8\/c8ZgTWHCm01CP\/uBkxFj+rHpUlRKggMtwghDASRiKxejH77Nn8XNvRk4SEpPnzbV1lCEPDs2CK0TCM9VzE\/ObPW+nBO2\/9vseV7RsZGqNhhIY\/I\/RxeODBFNYlwADPz0udTwDWrPufXTuNufy\/134flzAncX4qmMSF9NZcYx9MVBdb9NF14nkOAFiev1anO3NDdfpKtfTerfC6695hDJR2y+Rw7+R\/pa+sZ1mOZVmWB8uuEwDx9Q++XVyuDZ\/pA63KKqVPeJw7FBgrDq3KGhiXulwKAA0FBcVXtakzI1JTlZfP6cOXR\/gDgMrYAbRm6QMEADTFyojU5RG90kHTppNCsI+HUlWtVFbdNauXNDw1JtyTELnUgxAC0Nam+iFT0wYA8qBZy2eadMR38nLftrIfqo3fjb6qzBA+M0JGND\/8p3kULR4AALSVVVV5BqXKfWC5rylNX5V5G2bGhHsC0Fr09PBMX7vwKWHEZkSSn5srRDEsWfX0y3aEhvKgX7tYX\/pPP3PJPnc2Pzdvx3tvdXR00JQd7731+q\/+zAMkzU99yFz6EhqWAMC+rFvHq1hJl8Ff5gZNt8OgUyaTQjdIvUnbxXPdL7zIAXAcx3G8mdAQ2kUcFRVcfVZZHeUrK1OS6MkBhKiF8JE8eLJcX3Wu4HYLAAAE05uMNxpbZ9STTUvfqXG+NNuAqODqs5rGON9RSgMJlkKLdFywphji5scBgL7qXCXETTY++UYM1ZkF9S2ihBbl5f8Ye1kB8XGTg6CnL61UqYMjZskJgO\/keM3ZAs38OF8AaCsrvlyqN5ZHXHkQR49IW+kP50pF1\/9T0HMcHIFCM1yx\/8VUVlb+WL\/Uuajr1Bd2QsK2czGPnhCGIQR4XsiYJ0AI8BfOncvPzXt328bOzk4A2PTb7e9u2wgA727buOm32xlC5qWl8cATGpkhtAsFoljPwwkNHcVeHTta2lV2qppns74af\/f7aIVU7gsgYeqDJjvfutN4Kc87fhbLcsBzVp41IITIg8eF3L2tVLXflQZEu5vi3gwhpK30Rl4JRKTFp3lCW+mNvFaGykevQpH+W9LTjmolCQiC260MCR4\/5e6tM9+aZjefzb8NAPKQOfODPFo72uSK2XHjp5jK25B\/pSEofnIwAGiKv2nyDzaWlAAhxFCldJ8S505AU\/xNxT0AgOYfghWTgzXVdxVz4tvzlEzvyjO9hQZk0VNnRxljNFVn6zzmjzc2iFqVl0oZFJphCaExT9vfTVdXVx\/3275CekLCYBq1+HGFtHkjoYFI0Y+LYRje+OM0mtAQFB3botV5a\/OO+MS5m367nUrbn7e8\/tbmHfPS0xlTVqZ4MHUgPHsPITQs8CzHubi4LJ8TPXPM3Xte6e4d2YHjJS5uXHXMz7ziV+gTlI3nznrOiOM4ljVv0Rg9EwIQEKz4\/nKdLiQyXW4qJSGEkPZWvWzStHFyAmBoUOrBUyhKz6gcPbFt2dygJAHBAGC4nV+nC4kMIPrbcoWM6I0VC4lMDwEAw+2z5RA3dZzcVLRWPcgVvdTemC20ldbpJk2YIv4VKO9W1jVV1tUBKKb9ZNYUAIDmG2eV7SHBU9IA7t6y+BCJ0BQDAAiJnNPrkqizJA+eE2\/nG0KGFglhbA1vxyfONQvQml21My7OkJ65Jwyd7iKxbpyQPM9OLgnJ82zdCDQSaOoaEAAJwxCGIcaxIgAAnjeGVmaJ6jIrcW7yggWE9ISfZyUl0kgPT3jCEzA1YwgQICBhGPKQQsN30+gLy3G8\/+gAH0WqgT8s525Usj\/xm\/sUAIwaM0b65CpjMNhmiwYAQkLGlzbpQhS9RpkJCYgeU3m66PRNAHAfHeJufNC9FKO9ioq+bpJNmpYgp4Y2LAkBUMDdy6fpzKKQCQtm+QJARDTAXejVogBhzg09098u1Y+Ol5pXnBBCQBY9LQEAANpKvs+9qQe4IUufuuDJyN6miqnCRCmz1ouV7HpnYucjR4YRvaJqFiSnpSen2ZzD0h\/npr+l9iZWzX\/iiflPPPFQeYg6UAxtpRPhunGib8rChY8vXCiUgAdIWbAwZcFCsTMegDHr8lnUxRZ9dZ2AE8\/9BYC28LUqdYUi6idA5weznKurK51Kw\/FmLRqvkLmrhBP3iPSeP+qjZ88Z3WMTIqRPExlHGI8nLAyxbWnKYhpYQEVWd\/fiydqeZbGnL90CAADZGAXIx8z1osVtrzxddOs+ALiPjxFXobnyriJx1TQPaC766tIpax\/Q6DlzpgX3DujeLT+Z1wQA4DUm0cv2h49CMzJgGEZiY9TpId2C8PAzjETikFwkEoZhevrl4mOTevZ0DRkgvGkNgqmHRMe+aYOI5wmhU4IJGOfT0JYN8\/Azg4EngsrQ+TLykDiPwBn03PgPVRmO7VPVBpeQiYtCAECR+NSYvkw9xi9IGG8lXTF9gcJ48FRCP\/IyHT\/VZ3YT+yoSMhwghBCGkdjum\/x4z0zPSDNd6MQ4YP6xqedkanEbhaZHYkwxSJ7whAfeOOeCtnIECRJHrHu38QhheODFdbFFH0Ij81Yc+vpoP2vl4zdqOAkNgjws7u5u6oamwED\/vk0fEJWqwd3djT4vrq5u97VaH1+fPu96UDTNGldXYy6DUxdbCHsGWzcKHx8VPj5qwEuGICOCWbMfu5R3Ta+\/PuCepVK32XMeo89dROTEioqyrs7OAc\/F2cUlInIizWVw6mIL3MoTQWziKfdIX5jo6FxcXd0mTbYSZRxYBqcutjDtR4M6gyCIw+ij64QgCPLwOPE8b\/VCoIwb5KIgCDLSUemsjJ3xPI+bEyAI4nBQaBAEcTgoNAiCOBwUmkcBulkBx3EVFRV2zA4fPixsNYIggwkKzYiko6Pj448\/bmkx7qTzySefNDQ0MAzzzjvvmFnW1tYKxx4eHl999RU9bmxsvHDhQj+zu3jxovi0rq4uMzPTTNSsJvbHwDK9qanpyJEj+fn5Qkp9fX1hYWE\/S4sMQ1BoRiSurq7jxo37\/PPP6alEIvH39weAgIAAlmUFAQKA3\/3udzk5OTk5Of\/6179kMlloaOi333578uTJGzduGAyG\/uS1Z8+eLVu2CKfHjx9\/\/vnnz549u2HDhl27dtlJFGPLwDKd47iXXnqJZdnPPvvsxIkT1Ozjjz92xJpDZNDAd2+PVBYtWtTR0VFYWNja2trQ0JCTkwMADQ0Nhw8fJoQ89ZRxYeeoUaMSExMB4Fe\/+tXKlSulUmlOTk5FRcXKlSttzWwQ0Gq1H3zwwZkzZ9zdjVuusyy7bdu2\/fv3R0REaDSajIyMjIyMkJAQy8SwsDDBj9W7wsLCrKZrtVqFQrFixQqFQnHkyJFFixZVVlaq1epp0xw+dxZxHNiiGamo1WqDwRAbG5ucnOzv75+YmJiYmOjv77969WpBZSi0RaPRaK5evZqTk1NcXNza2nr06NHTp09Tg927d182vSpMzK5du7y9vTdv3iyk5Obmenl5RUREAICPj09CQkJeXp7VRLEfWwa20umCGPquD1qM119\/8F0skeEEtmhGHlVVVVVVVVeuXJk0adKyZcssDViWFXc0aIvm2LFj9AAAdDrdokWLBAOZTObs7Gzp59e\/\/jXDMLStRNFqtRMmTBDfeOvWLQ8PD8tEsR+rd9lKX716tVqt\/vLLL8+fP79ixYqKigqWZSdOxH01RjYoNCOP8PDw8PDwlpYWhUJx+PBhX1\/f+vr6zMxMAKAHV65ceeONN5ydnTmOc3ExvhA9MjKS2qhUqpiYGLHDdevWWc3IcocUlmXFiQzD0B2JLBP7vMtWOsMwe\/fuvXjx4s9\/\/vPY2NjXXnttw4YNNTU1\/\/73vydOnLhixYoH+KSQYQN2nUYwTk5OTz75ZEpKSmhoaEpKSkpKSkBAQEpKyqZNm2gLRafTeXt7A8C5c+e8vIzvBA4MDHzvvfcaGqy+EK8PXFxc6HvFKBzHOTk5WU3s8y476d7e3hkZGbGxsUVFRTKZLDw8\/JVXXomNjb1+\/fqBAwd+RLGRIQeFZsRTWVk5adIkq5e+\/\/772NhYAEhNTZ06dSrVI7VavWjRIjpK9aCMGjXq5s2bwqlWq50+fbrVxD7vspMu8OGHH\/7iF7+4ceNGWFhYenp6WlratWvXfkSxkSEHhWak0tjYaDAYtFptXl7e6tWrrdrcuXMnLi6OHkdGRhYWFu7du1epVD777LNisxs3btTX1\/cn0xkzZgAAjdpUVlZeunRp1qxZVhPFnm0Z2LkRAPLz80NDQ8PDw+VyuV6vBwCWZXHjpBEKxmhGHhzH7dq1a+HChc3Nzfv27XvhhReEdCHcK8SDadcJALRarUqlunPnztixY6uqqsLDwwWHf\/3rXxctWtSf8AfDMG+\/\/fZvfvObcePGlZSUbN26VaFQAIDVRLFnqwa2vFE++uij7du3A0B4eLhEItmzZ092dvbLL7\/80J8fMgSQJUuW\/N++Q80G8ykVuE3EsKWurq68vDw1NRUAamtrP\/\/8c5VKVV1dbTAYOI7r7OxMSkp67bXXWlpanJ2dg4KCrl69qlardTpdRkaGh4dHVVXVP\/\/5z5ycnMWLF69fv97V1fVHlEGv17u6uppFi60m9sfAMt1gMJSVlQlzZ1iWzc3NDQ0NFU\/PQYYhlttE+LqRnz+\/BoXmkUWv10ul0rKyssjISKsPPx3iGfyCIY8wtoQGu06PLFKpFADszEBBlUEGDfypIQjicFBoEARxOCg0CII4HBSaIaapqUnYjKqmpsbqfi5arVZ8qtFo6LwSO5SUlAhuWZYtKiqytGFZ9u9\/\/7vZcoE+EbZuEKisrOyzPINMY2OjcHzx4sWampohLAwCOI9myPnuu++6u7tfeuklALhz505NTU1kZKSZTVZWVkdHh7Amu7y8\/ODBgx999JHYprKyUqVSNTc3l5eXOzk5ubm5ubi40IXREolk3759O3bsMHN78ODBoqIinU4nl8stCybMxDEYDG5ubkL6zp07k5OTaaSZEhQU9Mtf\/nL37t25ubkcxwnrOVUqlaenp3j1plXq6uoqKipCQkIsK27HwGqiSqUqLS0tKipqampau3ZtdHQ0AGRnZ9tazIUMGtiiGWLy8vKef\/55ekwI8fGx8gLmZcuWXbp0STh1dnb28\/Mzs4mIiEhMTFy2bFlTU9OGDRteeeUVnU4HAF9++SUAyGQyM\/vKysrLly\/v3Lnz8OHDbW1tlpk+99xzOTk52dnZVAQFXFxcxCpz7ty5goKClJSU7u7uuXPnJicnJ5qQy+V9TtL5cTtm2brL398\/JSWlvr5+69at0dHRQmNNPA8QGRKwRTOU5OXlLVmy5ObNm83NzQBQUlLS3t7u7u7e0dFx+PDh7du3C7rz\/vvv2\/HDcdx\/\/\/tfmUwmkUgaGhqys7MJIXq9vqGhITc312x7GgBoaWn58MMP3377bQB45pln3n333RdffDEkJERsI5FI6Dzj48ePZ2ZmMgxDmyptbW3Hjh3Ly8vbsmWLRCLR6\/UuLi5r166trKykDaiWlha1Wk2P7WNrQyz7Bnb22RIaU3q9vqurq6Cg4N69ezTlH\/\/4R3Jycn9KhTgCFJqhZM+ePatWrRLmvzo7O9+\/fz8lJQUAxD2OlpaW2tpas70dKKdPn05PT2cYJiMjIzMz8\/79+\/7+\/oSQmpqa6OhoZ2dnca9H8Pbpp59u2bKFrk6QSqXx8fF\/+tOfpk+fvnLlysDAQGomXnU5b9484Rn28PCgz7aZ23379qWlpUkkkuLiYldXV7NHevfu3Y899ph4KRPY2PhKLDRWDYKDg63epdfrs7KyWJatr6\/\/5ptvvLy8ampqMjIy7ty5AwDPPvvsT3\/6008++URYk4EMJig0Q0ZmZmZ8fLz9\/TQbGxuvXbtWUlLi7u7u4uJSV1fn7OxcUVFRX19P1yJyHKfRaLy8vE6dOnXr1i0hYKFWqyUSieWq7srKyps3b65cubKgoMDJyWnv3r0\/+9nPpFLpH\/7whxMnTmzevHnr1q0BAQEAwLIs3b8GALRabXV1NV0DaQtnZ+eEhAS6PYVlX8zq3lq2NsSyb2Brny2pVLpw4cLjx48TQlJSUgIDAz\/44ANBtlxdXdetW+fh4WGnCojjQKEZGurr6728vCZOnNje3g4ABw4cGDt2bHFxcXt7u5eXV0lJSVpaWnh4uJ+fX3p6upOTU2dnZ2RkJNURd3f32tpaYf0kZcGCBeIXHowbNy4gIMBs+\/GWlhYXF5elS5cCAG0RHD16lDagamtrZ82a9eKLLwrGEomEXjp16pRCodi5c2d7e3tSUpKdSuXm5tIWjXjFJsVqOPbH7Zhl\/67c3FyFQvH+++8\/+eSTgjJ2dXUplcrQ0FCrGwkigwAKzdAQEBAQEBAgNBmuXbu2bt06QTtOnjwpdGH6Q0lJybFjx6ZMmeLu7l5cXLxx48adO3cCgFnMWC6Xy+XykydPCtvuqdVqoQyWAWMxTz311LVr1+wLjZ0WjVUsN74SCmbHwM5dOTk5y5cv\/\/rrr998883q6mqhtFVVVR9++KGwzB0ZfFBohilW3y7S1NRkdQAlOjqaDuX+5S9\/kUqlJ0+efPrpp+kqp66uLjPjhQsXlpWVXbx48YUXXjh69OjUqVNv3rxpqSCtra3i05iYGKtBIgGO44QWTWhoaD+qaGXjqwULFvRpYOsuvV6v0+kSExO\/\/vprquPUYPny5d99992qVavM2oDIYILD2yMDvV6\/Z88e+8O0Fy5ciIqKioiIeOaZZw4dOkTHfdesWWNmptFotm3b9sQTT9BThUIxevToV1991WyuoFqtVqlUKpVK3HywQ0hICB3VTkpKsuw6Wd1by9bGV4LxA+2z1d7ebnXOzoULF6KjoxcvXtyfWiAOAls0wwJx5BUAhEFZil6v371798GDB+14yM\/P7+zsXLx4cXZ2NgD88Y9\/\/OKLLwBgxowZ4hCGVqv99NNPP\/jgA\/GEncjIyDfeeGP9+vX79+8XumyTJ0+mx8JeU01NTd7e3t3d3VYLIMR3YmJiGhsbtVqtTqfz9fWliVb31rK18ZVg\/ED7bAkqLChjfX393r1758+fL2wziAwVKDTDgpaWFhp5pVy5ckV8NTEx0cvLS3iQLHtDTU1Nfn5+9HESrtL9PYuKirZt20b\/1BsMhvz8\/E2bNgHAuXPn9u3bFxUVRY0jIiK2bt0qDpFs3bpVuEQPdDrdtm3b5s6dK86a4zjx\/D2Kn5\/fiRMn9uzZs3\/\/fpqye\/duqxWPi4s7c+aM2cZXYmOrBlYTBbq6umpqaurq6rRa7caNG3E3jOEAbnw1lDQ0NMjlcjc3t66urv4PiJitCTBDo9GYTS9uaWmxusjAVrodzN4YNYDGAwjd8Wvw80UAN74angiT4h5o2NWOygCA5SIGW2ryoCoDNkLUA2I8gKDKDEOwVYkgiMNBoUEQxOEMcNepoKBgYB0iCDIkzJw5cwC9DXyMxtZbExEEGSmIp0QOCA4MBo+9kuw45wiCOIjq+AsD7hNjNAiCOBwUGgRBHA4KDYIgDgeFBkEQh4NCgyCIw0GhQRDE4aDQIAjicFBoEARxOA6csOeIaT8IgoxEsEWDIIjDGfgWzYCvkkAQZKQzwEIzsCs+EQR5NMCuE4IgDgeFBkEQh4NCgyCIw0GhQRDE4aDQIAjicFBoEARxOCg0CII4HBQaBEEcDgoNgiAOB4UGQRCHg0KDIIjDQaFBEMThoNAgCOJwUGgQBHE4KDQIgjgcFBoEQRwOCg2CIA4HhQZBEIeDQoMgiMNBoUEQxOGg0CAI4nBQaBAEcTgoNAiCOByb73VS6VCDEAQZGFBNEARxOCg0CII4HBQaBEEcDgoNgiAOB4UGQRCHYxx18nUjQ1sOBEEeYciSJUuGugwIgjzi\/H8f2e5iQq6cwgAAAABJRU5ErkJggg==","height":109,"width":360}}
%---
%[output:843b74c1]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAjAAAAGkCAYAAAAv7h+nAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnb+PFkfW74twdG9EdA0JwcgOXmk3M5pk\/wGTshOZyBahE5CRIGRWWBBbQrAJjgyRpdf\/gBNEammDAYKJ8Bvh5F4RzlU11OOamuquH13V9esz0mp5\/FRXnfM556n+9qnq7gunp6engj8IQAACEIAABCDQEIELCJiGooWpEIAABCAAAQhMBBAwJAIEIAABCEAAAs0RQMA0FzIMhgAEIAABCEAAAUMOQAACEIAABCDQHAEETHMhw2AIQAACEIAABBAw5AAEIAABCEAAAs0RQMA0FzIMhgAEIAABCEAAAUMOQAACEIAABCDQHAEETHMhw2AIQAACEIAABBAw5AAEIAABCEAAAs0RQMA0FzIMhgAEIAABCEAAAUMOQAACEIAABCDQHAEETHMhw2AIQAACEIAABBAw5AAEIAABCEAAAs0RQMA0FzIMhgAEIAABCEAAAUMOQAACEIAABCDQHAEETHMhw2AIQAACEIAABBAw5AAEIAABCEAAAs0RQMA0FzIMhgAEIAABCEAAAUMOQAACEIAABCDQHAEETHMhw2AIQAACEIAABBAw5AAEIAABCEAAAs0RQMA0FzIMhgAEIAABCEAAAUMOQAACEIAABCDQHAEETHMhw2AIQAACEIAABBAw5AAEIAABCEAAAs0RQMA0FzIMhgAEIAABCEAAAUMOQAACEIAABCDQHAEETHMhw2AIQAACEIAABBAw5AAEIAABCEAAAs0RQMA0FzIMhgAEbAQuXLhw7j+fnp4CCwIQ6JQAAqbTwOIWBEYhIIWLLlOkjFHCZfoOETNKKuDnYAQQMIMFHHch0AMBvdpi1lh0ASP0qgxCpofQ4wMEdgQQMCQDBCDQDAGz2iKkKDGWjiYB4\/IIMeMixPcQqJ4AAqb6EGEgBAYnYNnbskTEJWDOVGgGR4v7EGiZAAKm5ehhOwR6IqAJFX07rrOaspYB1Zi1BDkeAkUIIGCKYGdQCEDgHIELF4SrerKamrHkRDVmNVE6gEAxAgiYYugZGAIQ0PevLIoXy16XLPSoxmTBSqcQyEEAAZODKn1CAAJ2ApZlot0S0VYixSc2CBkfSrSBQFECCJii+BkcAgMQ8N2EW5OAUWFByAyQoLjYKgEETKuRw24I1EzAV7TU7AMipoXoYOPABBAwAwcf1yGQnEBPwgUBkzw96BACKQkgYFLSpC8IjEqgR+FixpLlpFGzG78rJYCAqTQwmAWB6gmMIFoQMdWnIQaOSwABM27s8RwC4QRGFC2ImPA84QgIbEAAAbMBZIaAQDcEEDBnQ8myUjepjSPtEUDAtBczLIbANgQQK27OCBg3I1pAIBMBBEwmsHQLgSYJIFriw4aYiWfHkRCIIICAiYDGIRDojgDCZX1IETDrGdIDBAIIIGACYNEUAl0RQLTkCSdCJg9XeoWAQQABQ0pAYCQCiJbto42g2Z45Iw5BAAEzRJhxEgJC6G9+hsfGBBAxGwNnuBEIIGBGiDI+jkmAakt9cUfI1BcTLGqWAAKm2dBhOAQsBBAtdacFAqbu+GBdUwQQME2FC2MhMEMA4dJeaiBm2osZFldFAAFTVTgwBgKeBBAsnqAaaIaQaSBImFgjAQRMjVHBJggsEUC89JUfCJi+4ok3mxFAwGyGmoEgEEkAwRIJrsHDEDMNBg2TSxFAwJQiz7gQcBFAuLgI9fk9IqbPuOJVcgIImORI6RACKwggWlbA6+hQRExHwcSVXAQQMLnI0i8EQgkgXkKJ9d8eIdN\/jPEwmgACJhodB0IgEQGESyKQnXaDiOk0sLi1lgACZi1BjodADAFESwy1sY9ByIwdf7w\/RwABQ1JAYAsCCJYtKI8xBkJmjDjjpZMAAsaJiAYQWEEA4bICHodaCSBgSAwITAQQMCQCBFITQLSkJkp\/NgIIGfJicAIImMETAPcTEkC4JIRJV94EEDLeqGjYFwEETF\/xxJutCSBatibOeHMEEDLkxmAEEDCDBRx3ExBAtCSASBdZCCBismCl0zoJIGDqjAtW1UgA4VJjVLDJRgAhQ14MQAABM0CQcTGSAIIlEhyHVUMAIVNNKDAkPQEETHqm9NgDAcRLD1HEB0kAEUMedEoAAdNpYHErggCiJQIahzRDACHTTKgw1I8AAsaPE616JoBw6Tm6+KYTQMSQDx0RQMB0FExcCSCAaAmARdOuCCBiugrnyM4gYEaO\/qi+I15GjTx+U40hBzoigIDpKJi4MkMAwUJqQOA8ASoxZEXjBBAwjQcQ8x0EEC+kCASWCSBkyJBGCSBgGg0cZlNtIQcgkJQAQiYpTjrLTwABk58xI2xBgErLFpQZYwQCCJkRotyFjwiYLsI4oBMIlgGDjsubEkDIbIqbwcIJIGDCmXFEDQQQMDVEARt6JoCA6Tm6XfiGgOkijB07gVDpOLi41gQBhEwTYRrRSATMiFFvwWeESwtRwsaRCCBkRop2E74iYJoI0yBGxogWOanGHDcIUtyEQFICiJikOOlsHQEEzDp+zR394sULce\/evcnu+\/fvi+vXr9fhAyKkjjhgBQRcBBAxLkJ8vxEBBMxGoGsY5u3bt+LOnTviwYMHkznq3\/v7+2XNQ7yU5c\/oEIghgJCJocYxCQkgYBLCrL0rWX15+fKlODo6Ent7e+Lhw4fiypUr5aowCJfaUwb7ILBMABFDhhQkgIApCH\/roaVgkX+3b9+e\/t\/8nM0eTahcEEKc+g7E\/hZfUrSDQFkCCJmy\/AcdHQEzUODNiousyJycnOwETRYUZpUFUZIFM51CoAoCCJkqwjCKEQiYUSL9qeKiLxllFzAsEQ2UXbgKAVle9a6vggsCqwkgYFYjbKeDLZaQLly44L9E1A46LIUABGIIIGhiqHGMJwEEjCeoHpqZFZekm3iptvSQIvgAgTwEEDJ5uA7eKwJmoAQIuY36iy++EMfHx4t0ZLVF\/VE4HiiRcBUCMQQQMTHUOGaBAAJmsPQIeZCdFDHybxIytgqLPiFRgRksk3AXAoEEEDCBwGjuIoCAcRHie7ETMq9fn6XBHUVkBwQgEEoAIRNKjPYzBBAwpIYXAbVcdGapCAHjxY5GEICAhQBChrRYSQABsxLgKIdPdxedngr1\/7xAcZTI4ycEMhJAxGSE23\/XCJj+Y5zEw51wEXI7zMfNu2zcTYKWTiAwNgFEzNjxX+E9AmYFvJEO1QXM5PeFCyLotQAjwcJXCEAgjgBiJo7boEchYAYNfKjb5wTMpw6oxoSSpD0EILBIABFDgngSQMB4ghq92ZyAUVx4Au\/oGYL\/EEhIABGTEGa\/XSFg+o1tUs98KjDqsXZysy+bfJPipzMIjEUAATNWvCO9RcBEghvtMFPA7JaOLBMN1ZjRsgN\/IZCWwJmLobRd01tHBBAwHQUzpyv6awPkOFOVZemPTb45w0HfEBiPgGvOGY\/I8B4jYIZPAT8Arj0wei96BYY7lfz40goCEJgnMM0jCBhSxCCAgCElvAiceXHjzLLRXEeyVoOQ8cJMIwhAYIYAIobUMAkgYMgJLwLmg+zUU3n1g\/X\/duZq6dOD73br2l4j0ggCEICAgwBVmaFTBAEzdPj9nbc9idd2tC5cbFUbnhvjz5yWEICABwFEjAekPpsgYPqMa3KvzE28ZuVF\/2zeoWRdfmKTb\/IY0SEERiPAstJoET\/rLwJm7Ph7e790F9Lcd0u3WqvnxLA3xjsENIQABCwEEDHjpgUCZtzYB3m+tBwkO5rbE+Ma5Ey\/rsZ8DwEIQMBFgCUlF6FuvkfAdBPKvI7YlpDm9rsoQbNk0bnqzKeNvnm9oHcIQKB7AgiY7kOsHETADBPqdY4u7YGxCRbbc2Nct2KrN1xP\/a0zl6MhAIFBCfAU33ECj4AZJ9arPJ2rwLheKaAP6v0gKqoxq2LFwRAYmsCnCkzIwzeH5tWw8wiYhoO3pemuPTBmFca15GTafq7\/T3cpUY3ZMsqMBYGOCJyeisUbCTpydVRXEDCjRj7Qb30isN0mbW7itVVblpaVFqszVGQCo0VzCEBALSWZF1eQ6YcAAqafWGb1RIkPnyfyLk0YS7djzzpANSZrbOkcAk0Q0JeGFgw298CwlNREdKOMRMBEYRvvINeTeFUFRRc6upAxl4h8JhXbnUo8N2a83MNjCEwEpICZqcaeeU2JcReSz1wD4TYJIGDajNvmVtuEia0aIw3z3f9iW5923qn0cYDN\/WdACECgLgJnloh00xAwdQUqozUImIxwe+p6bjOcbW\/M2bnEvZHOS7TonSJgekotfIFAMAHz6btLVRYqMMF4mzkAAdNMqMoa6trNP7e3Zakas7Qx2ObtGaFTFgejQwACGxI4V22xPKxu6SLL+xEOG\/rEUOsJIGDWMxyih9C9LbY7lUxQPncqOaszVGOGyD+cHI\/AmX0tcuXYQDAnSsyKCxWYfnMHAdNvbJN6NreJd06EyMHVrdW29yQp45aOV304HUHEOBHRAAKtEDCFi7RbXzLyuZPRrO5SgWkl+mF2ImDCeA3b2lYJSbWspN\/BpAsb15XTOZsQMsPmJ463TcC6IffTg+jMOxwnQWP81peqMd4XQm0jHNJ6BMyQYQ932neTnCkqlva5+ExCS3cqzV5VIWTCA8wREChAwGdZaM0c4rrIKuAyQyYkgIBJCLPnrlx7UVwTxdwSlMnMdSXlfTX1ScTw3JiesxLfmicQcMuzOYfYKre2+cRVyW2e4cAOIGAGDn6I67bJI3RZyeeOJH0JSS8V6\/togtezqciEhJq2EEhOwPeZLeZv3jQkphqDgEkezmo6RMBUE4q6DQnZxKsmIfMKaW4te+lKyudOJSc5BIwTEQ0gkIPArgIacNuzssNn2XpuyVq\/EELA5IhsHX0iYOqIQ\/VWzC0hzU0OIUtOc5WZpWUp15LVOaCImOpzDAP7IKBEi758az54TvfUJVRkW\/NCZmmvnX4BFTxP9BGCYbxAwAwT6nWO+oqJuU23rr0t+i3XehlZv5KyeRA8QSFk1iUCR0PAl4Blf4tNjOi\/d9c8YZsPfPbGBC87+\/pIu6IEEDBF8bczuJokbFdLrmqLOUEtXT2ZgkQfd27y06+4vIhqIoZNvl7EaAQBfwLG7c\/mgSEVl6V9c2YVR80PtvkFAeMfvpZaImBaitYnWx8+fCiePn06fbp06ZJ48uSJ2N\/f33mif\/\/s2TNx9erV3XcvXrwQ9+7dmz7fv39fXL9+3YvA3B4YU1T4Vmpsg\/pcSblEzNL3s45SlfHKARpBYLpYkEs62v\/vqGSouPjugbMJHT1aCJg+cxcB01hcpQB5+fKlODo6Ent7e0J+fv78uXj8+LG4ePGiePXqlXj06NH0+c2bN7t\/y+\/evn0r7ty5Ix48eDB5rf6ti585HLZKiM+VlG0S8RU5m1RjphmZt1s39jPA3EIEzlQsPwkW1zKua55YepDl3AWJa9+cOs5lWyGMDJuIAAImEchS3eiiRAoRWX2Rf7dv3xYfPnwQd+\/eFYeHh1MVxhQ\/su2VK1e8qjBzE8Hcnhefq5+QiW3uTiXXmnnQlRdCplQaM27lBJbuJlKm+16YmK66RIY5TyxVW\/Tfu8\/SduXYMc9BAAHTeIroAuby5cuTYDk4OJhEiRIw6rMubqTb5uclFD6TjDp+7o4B13uTlia2TaoxCJjGfw2Yn52A5XZo2+926cLCfDea7fEKc3OBPseYQsbnsQ3Z+TDApgQQMJviTj+YFCF\/\/PHHtKQk\/\/SKixIpqspiVlxkRebk5GSq1rj+5jbT+m6yk\/37VlxcQibmuTGyT6oxrijz\/cgEZje0e4gWn6rKnODQj7VdqMyJFle1hQpM\/9mMgGk4xlKA\/Pjjj7tNvOaSUQ4Bo3C5ysUxSzs+VR7bE3l9JkaXgLKmARWZhn8dmO5DwPbm5+m4CNFiG29JRMxd0LiWiJYummzjLV04+TCiTb0EEDD1xmbRMlO8yMbmklGOJSTb1VDo0pBLTLgqNaqasnS1NldxcYmkc9ARMY3+QjA7mEAi0aJ+3+b4S\/OEra1r353+G59bYnbNNcGMOKAqAgiYqsLhZ4x555F+lL5MZNvEqy8ZhW7ida1rL12BhYocl9DQRY75b92OGJutUeDZMX7JSauqCZyruCQULbpwSXH7s2vjvmuJyPV91YHCOC8CCBgvTPU0krdJy9ufzWe\/KAtT3Ub9xRdfiOPj453jrskgRHCYNF0VF5\/lKKox9eQoltRFIOXelqWLFL0iMkdgaXlIHWPb22Ju\/DXHip1D6ooU1oQSQMCEEivcXn9InW6K\/sC6VA+ykyJG\/kkhM1fxCBUjc5Oca0\/N0uS4eTXm46Xm5DpP8i38g2D4WQLW3ExUcXFd0LiEjv793F2L+m\/eZ5+bPof4tCd12ieAgGk\/htk9kELm9evXZ+7iSSU4cgigTaoxiJjseccAiQgkEi0fU\/6jcPe9o8+34mIKIpcAmau42OxjE2+iPKqwGwRMhUGp0aSlCcNniccmVGKqMWoS9dnbssneGE3I1Bg3bBqDQE3VFpv4cG3IdS0b+W4Atj0LBgHT728AAdNvbJN65lpjXroqcx3rI0ZiBZCtGmO7FVvvP\/QqczqWu5WS5hudRRBIWGlJXW1Z+8wWcw5xVWgUvajfcgR6DilDAAFThntzo\/pcxbiESkzFxTUBuca0PeUz2+SHiGkur7swOKFwCd3bsrRE5Hoit20s1+9ZxcvVNwKmi8x2OoGAcSKigWvZJqR64Zqgci5HxVRjQnynEsNvZUsC\/\/nj\/07D\/df\/+V+rhg0VLXp1Rl2UuJaI9IsXn4sSW3t9LNc8oQsdn4uvVQA5uBgBBEwx9G0NHDoJuIRKTDXGJSZcY25VjfnP\/\/w\/8V+f\/e9dgLlTqa1cr9laJVpSCpcUG3LXLhGZzF2iyiaC5iqroXNXzfHHtrMEEDBkhBeBmEnA50or5\/6XuUlx7nUErr0xLgGljydFzHSS0YSMF2gaQcAgoIuWtcLFJQyWhIReAbFdgCyJilCRZAoin4qLbVlJ\/aZ9xyf52iKAgGkrXsWsjREwytglIRP7nUtMuKox+mQ898TP2CoRQqZYmjY9sFmpyyFcfE\/kvntb5vaxqED4jOcjqvR5wmy\/Zg5pOmEwXiBgSAIvAmsEjC5kYisuriuwpdssXWPa9sboUFzH+wBkWcmH0lhtXIJF0Yjd4+IjDHTivqJFXTzoAj90LFsfruiHVnRjbHLZwPd1EUDA1BWPaq1JIWBck9aaKylXxcVHAJl9zK2p2yZ9nyvN6TjuVKo2x0sZZlZa1giXmJO2b0Vjqdrim\/+h9oWOOdfe175SOcC4cQQQMHHchjsqlYBJUY3Rr\/x8xYTv1dsW1Rhps16RYZPvcD+nyeE54SK\/C626uPLbJOxbbdlqiWjOviXhoc9Jtt+tbdP+mJnWr9cImH5jm9Sz1AJmTTVGHRuztOOq1ChxFCNkQk8iVGOSpmgznaUSLmuqGXN5rl9gmBcKofkd237uAmVJhC0tIfv210wCYeiOAAKGZPAikEPA1F6NMYWSz5KSS1zNwr5wgRdDemVi\/Y3mKmophEuoaNEvFGzktr79OVSE2Gy2CSPXhQlLSPX\/bmIsRMDEUBvwmJwCpmQ1Zu7qTJ8kqcYMmPAJXF4SLKp736WiNdUM0xXb7cb672CNSPIVCmv88d3Ppvvta1eCsNPFhgQQMBvCbnmo3AKmVDXGVTEx19nnbrmOWc6y5gObfJv5mXx8L7MQp4bFqYTLGiGhBMmcUAjdHLtUCZm7CFhbbVnjv+9zZJpJNgy1T5enSFNSw4PAVgKmxWqMeliWTzXHA\/XHJp+EDBt8vYlt1tAmXHxEizTQp+KypjphQii9ROT6PS8JI99Tk0uMbTl3bZaEDPRxmkTAkAk+BEpMAq517RjB4Do5uMa03dkQsjfG92oVEeOTldu18X1mi82iENHimx+2nHNVW2xiJlQkhLaP8cdnDN\/qjOv3vl0GMVIOAgiYHFQ77LOEgPG5evMVHGZIXMf5iCPb3hhXNUb55DNJn7GZpaUivypbBcxVbfERLHpu+57kzWNqq7b4igrd7lCBkbt9kSRj0GgCCJhodGMdWErAKMopBIdNxCydPFxjlqjGTCcxy76LsbJxe29T3EGk53KtosXnoiH0dzTX3pdBqDAy25eeu7bP1nFGRMCME+tVntYwCbiuvnwFR8gEvDSm\/t1m1RgqMavyeO7g0FuffasspmiJOWmrY7ZYIoqxz6eaGCpCUgqpGuauLElLp+yBIQf8CNQ0CbiEytwknFMAbVqN+Ti7T4GjGuOXv7ZWip3P\/pZQwdJCtaWkqJgVkppATyWMapq74rOVI62\/YTbxkhg+BGqbBHKKkRgBRDXGJ4vqaeMSLbGCRa8cxFQztqy2+AiEtf74jJFbSNU2d9XzK2jfEpaQ2o\/hJh7UOgn4LvGYkLYQQDozfZJWtiw9\/txn4t\/5xLJS1G\/A3NeypWixCYO5E7ntv4ee9HO31\/3xzV3Xb3DuN+srDPUqmK9NUYnEQcUIIGCKoW9r4FoFjM8k5Vpy8nmyZ6wAsu2N0ftK\/QA8lpT+oju3RDS1ODUfPxf3e1xzEjZHTP3MlhpFxRZCyvZbRcDE5XftRyFgao9QJfbVLmBck3VspUb1GyM0zGWluRPU3BVl6MlRfznkyELm3IPmEokVXSwvVdGWKgcq1mzIXZ7YgnN\/obsW5q5KpvnmzEDANBeyMga3NAlsXXFxTbbKnq2rMWUypeyoO\/GSWLS4BLLNa9uyoU34lFgiWuOPbzWjRLVlLg6+NpfNXkYPJYCACSU2aPuWBIxrcvYVHKGToUs4zV19myc69saE\/cjOVJtOT0XKXF1zEt6y2uJ7gl7jj88Yof27fqthmWBvnTIfUthDH+kIIGDSsey6p1YnAZeoSL3\/JUQc6bb5iBg12fucSKZkNDb39rKspKosk0DQf3Wfqi5rc3XNSdgULeqzMrNEtWWNP7655sp7c3KMsSl2gl2bD7Hjclx+AgiY\/Iy7GKHlSWBpcnVNvLkFUMyykstma8Llfm6MWrLJdEeUdUPuzDJRbK6Gct1yiSimUrHGHx\/hEipCQtunmjhj8yHV+PSTjwACJh\/brnruYRLILUZsAfcdM3s1Rjcuk8jIkfDnqkYee1tCcjX0pGqrlM0JBdt\/70FUxPrgI4qy5NCFC6LU2Dn8oc+\/CCBgyAYvAiEnBa8OCzVqrRrjejlk6Mlkwl65gLEuEXkIF32ZxnXCCuW2ZbUlVFT1UJ3JOR30MnflZNRq3wiYViO3sd29TQKuyojEG7qZ1nVSdI256esIci8pReRnqtuf5ziHCgNf0WITEKFjrREhc7lqhiDUptD2MT5EpEnwIb3NXcEAOj4AAdNxcFO61uMkkEpw2E4UazcHm7Yp\/mtsns2HghWZc9WWgErLnD9zy3GuqoxewVH\/XqqA2U7wrvi0ICpy+5ByXvLpq8e5y8fvEdogYEaIcgIfe54EXJWR7qsxHy+d12eJ50beM5WWBIJlrSjQKwc2CKmfkLtFZSN0jNzt1ydXfA89z13xVPo4EgHTRxyze9H7JOC66nSJnLUVl7mTsK0CkK0as0bE6EJkpp9zS0QflWGy3F1zElYidS4PbP\/dlTNLMfVxeo0\/odWmXO19\/Mzdpve5Kze\/mvtHwNQcnYpsG2UScAmVmGqMusKPfR1Bib0xk82256y4RI4UJFqbtRtyfX4Cc8ttc8fqwsBs03K1JVSEzOVyioqWT9y2ajPK3LUVz5rGQcDUFI2KbRlpEnBdWbtETm\/VmJ2QMcSJNV0\/PQlXfed7Ug1N\/aXqhC0+vqJFiU395B5aCbH14fIvdIzc7WN8cPlY6vuR5q5SjEuNi4ApRT7BuB8+fBB3794VBwcH4vr167seHz58KJ4+fTp9fvbsmbh69eruuxcvXoh79+5Nn+\/fv3\/muCWTRpwEloRM7HfqxBBbjVEnVj0etpNz6B1Us7HX71ZyCJic7yHST6i6uLDZPceGDbnuSSdUGLl7LN9ixLmrPPVtLEDAbMM5yyhKjOhC5NWrV+LRo0fi8ePH4s2bN7t\/X7x4Ubx9+1bcuXNHPHjwYLJH\/Xt\/f99p38iTwJqKS+pqjC6AbEsneiBjRJJTxBoNziwRJdzPog\/jqoiZNvtWW2wn69ATeGh7XYj5VqdCx8jd3jlZVNZg5LmrslAkNwcBkxzpNh2+f\/9efP\/99+LPP\/8Uh4eHu0qKrL7Iv9u3bwtVoZHfyyqMFDwvX74UR0dHYm9vT8i2V65c8arCjD4JxFZcXCffNeLIVo0xKxVz1QqXXUsVmS1Fi6vaouw0RYtPtcW23yVUVIS2j\/EndIxc7beZ2dKPMvrclZ5oPT0iYOqJRZAlUnx8+eWX4pdfftktIZlLSuZnXdzIwczPzqvvTFfYQY4XbpxCcMxVDGKWfZQ9m1VjzCWlxPEIFVY1V1tCKyE1VmcSh7dIdwiYItg3GRQBswnmtIPIpaCffvpJfPfdd9M+FrUHxqy4KJGiqixmxUVWZE5OTqZqjeuPSeAvQrHVGHWCilnacQknvRqjX+XbKhMhAmouL1LmQ+iJ3iVadNuWhF2uSsUaEeZjUyivGGHkmg9a+j5lrrbk9wi2ImAai7IUKXIPy9dffy0uX758ZhMvAmbbYLpERer9L64To3ni1m+\/1snECCib6PE52S4JIPWdbz\/miXuOh+0E72I3J+p0MbiUXaGiIrR9jAiJGWPbX9A2oyFgtuFcYhQETAnqK8aUm3R\/++23M3tczArM3GeWkFaAnzm0VDVm7sSq2xOzrOR7oo89Kfj2r3C7qi1z7fQ9MLlEyBpRESvaXBmMaDlPKDZXXaz5vjwBBEz5GARZoN8irR\/4zTffTKJGXyaybeLVl4zYxBuEfrHx1tUYdfL0qabYllRc1Q\/XpO\/6XocVelI1RctoG3JDecUIqXSZX39PIblavzdYeGZuOfW9FIBbdQRsz4FJdRtlxKrdAAAgAElEQVT1F198IY6Pj3c+Mwm4w99aNWZJGLhOiq58WHMStpEOeUKuT8Ul1L7Q9i5+Nh\/XVKeYxud\/n65cdf+yaVErASowtUbGw67cD7KTIkb+SSHDJOARkE9NXNWYuRPsFgIothpj2jzn45qTsEk4RLSYbWP2H5UQFVsII\/\/M7bMlc1efcZ0uEqjA9BvcVJ5JIfP69WvBVZ4\/UdeJ3CVyfJaGTGt8BZDZTtkSYvOcEPLJkdxLRCbbUJGQu\/2a6oxPdck\/S8doiYDpN84ImH5jm9QzJoE4nC6h0mo1RqfhI1r0k7aNZGy1Zalqor4LtS93e18REiqk4jK0\/6OYu\/qNMQKm39gm9YxJIB5nSGXDVlWJWQ7ZshqzRCZ3tSWkCuUSOz7CJVRUhLaPqc7EZ+YYRzJ39RtnBEy\/sU3qmbmpN2nng3TmKypCT8quKo\/PclTo3hjXScEULnMVG9sJPvSkb7YPsc1HtMSICpdonYuxb3VmkJ9MEjdd+ZBkEDopQgABUwR7e4MiYNLFLIXgCBE5vsLJbGernqhxbT5sKVqWRMUc39yiYq3wSpdh9KQTQMD0mw8ImH5jm9QzBExSnNNdXXNX27HfqZO6T8VlSQCZE\/7cMpD5sDjlz5z9tv+eQ1TMVZN8qi2hImSL6kzazBuvNwRMvzFHwPQb26SeIWCS4tx1tqYak1MAuaoxSzRSbsjVBcKcv3NizLf9GhHiO0aMMMqTceP1ioDpN+YImH5jm9QzBExSnGc6K1Vx8dkcvCRkeEKuOydCK0zuHmkRSgABE0qsnfYImHZiVdRSBEx+\/LVWY1SFwvZyyBqrLa4TVqioiG3vW53Jn1ljj+DKh7HptO09Aqbt+G1mPQJmG9SlqjFzJ1vdHvPfcy9MjFkuiRUJtiqS7YQValPu9ttkE6OY4hsifRFAwPQVz2zeIGCyobV2vHU1xjXR+2yMjRUhvpUKX1GhbPVtrwcg1gefDcLbZhCjKQJUYPrNBQRMv7FN6hkCJilOr85qr8bMVWCWnKtRVITaFNreK9g0ykYAAZMNbfGOETDFQ9CGAQiYcnFyVWN8ln9M612VBp8xfSsnqroT0973GF1U+BwTI0JczMplCCO7RDMVsj5zBAHTZ1yTe4WASY40qEPXydMlONY+G8YmgFwnhVCRENp+Thi5WPgIHOVvjE1BgaVxdgJUYLIjLjYAAqYY+rYGRsDUEa\/Yk3Pq5ahYO2wUXeJsrnq0VHly3R3lumJX37tEWh1ZgRWueBLHPnMEAdNnXJN7hYBJjjS6Q9cJ3yUufJ7\/Mica9FuptxQJIZUQcxOv78nLxTU6YBxYlAAVmKL4sw6OgMmKt5\/OETD1xdIlVJYqFHPfyf\/u6nfuFQI+hEJFQmz7Jf90O0OEkY9\/tKmPAAKmvpiksggBk4pk5\/0gYOoMsOsE7yNGbJ6tWXKaq97kEhWmCPE5Ybm41RltrIoh4JMPMf1yTHkCCJjyMWjCAgRM3WGKFRyuE\/nc5O86KcRUNly2zAkjc4loyWbVh++yUt1RxzofAq5c9emDNnUSQMDUGZfqrELAVBcSq0FrKi4he2NcIsFXIIQKHZ\/2um0+7duILFbGEkDAxJKr\/zgETP0xqsJCBEwVYfAyYotqzBqRECMqQqozMf17gaVRkwQQME2GzctoBIwXJhohYNrLgTXVGOnt3HuGTBKh1ZbQ9nO2zC0p+bZvL6JYHEMAARNDrY1jEDBtxKm4lQiY4iGIMiC2GiMHixVAuqGh1ZDQ9spOXbRwwopKlW4PIh+6Da1AwPQb26SeIWCS4ty8s1gxMieAXP0pB0OrLaHtbdUWTlibp1fVA5IPVYdnlXEImFX4xjkYAdN+rFNWY2wnhZB9KnrlxHfJx7c6wwmr\/VxN6QH5kJJmXX0hYOqKR7XWIGCqDU2wYa7qic\/dSKoPX1FhW1YKrbaEtPdtGwyPA5ojgIBpLmTeBiNgvFGN3RAB01f811ZjYpeIUldbbFHhhNVXrq71hnxYS7De4xEw9camKssQMFWFI5kxrmrMnODwOSlsUZ1BwCRLhW478snVbp3v3DEETOcBTuUeAiYVyfr6ce1dmdvv4rPU5ONtjNBZ6pcTlg\/1cdqQD\/3GGgHTb2yTeoaASYqzys5CqjFm21AREto+BBgnrBBa\/bclH\/qNMQKm39gm9QwBkxRntZ35VmN0ATK3zDS3vBPSPgYUJ6wYav0eQz50HNtTtuv3G92EniFgEsJsoKuQaozLnZzVljmRxLTmiso43yNg+o01FZh+Y5vUMwRMUpxNdOa6U2lJJGwtWhTQUuM2EdBBjUTA9Bt4BEy\/sU3qGQImKc6mOrMJmbmTgmsJKofjc6KlhC05\/KPPdQQQMOv41Xw0Aqbm6FRkGwKmomAUMkU\/EZj\/ViZtuXTjK1A4gRVKmEqGJf6VBCKDGQiYDFB77BIB02NUw30yN+\/KHkqIltBxfcVOOBGOqJ0AAqb2CMXbh4CJZzfUkQiYocLtdHbLk0LKfS1b2u2ESINNCBDzTTAXGQQBUwT7ukHfv38vbt68KX7\/\/fepo2fPnomrV6\/uOn348KF4+vSp9bsXL16Ie\/fuTd\/dv39fXL9+3csYBIwXpmEabXFSyFU1ydXvMMFvzNEtcrUxJN2Yi4BpLJQfPnwQd+\/eFZ999pm4ffu2ePv2rbhz54548OCB2N\/fF69evRKPHj0Sjx8\/Fm\/evNn9++LFi2faSrf141wYEDAuQmN9n+ukkLLa4ooIQsZFqI\/vc+VqH3Ta9gIB01j8pGD54Ycfpv9JUWL+yeqL\/JPiRomdw8PDqUIjqy8vX74UR0dHYm9vT8i2V65c8arCIGAaS5TM5qY8KWwpWmxYUvqSGTvdRxAgvhHQGjkEAdNIoJSZpgjRzVeC5eDgYBIl5mdd3MjjzM9LKBAwjSVKZnNTnBRqqoDUZEvm0A3XfYpcHQ5aIw4jYBoJlC5gTk5Opo\/mPhez4qJEiqqymBUXKYZkX7Ja4\/pDwLgIjfV97EmhdLXFFaVYv1z98n05AsS0HPvcIyNgchNO3L\/ahKs27so9L3Ivy5MnT8Tly5en\/TFqyQgBkxg+3e0IhJ4UWqpwtGQrKekmEJqr7h5pUQsBBEwtkfC0w1xC0peJrl27NgkYlpA8YdIsmoDPSaH2aovLeR8fXX3wfXkCxLF8DHJZgIDJRTZTv7Li8vPPP+824prLRvoykW0Tr75kxCbeTEEaoNu5k0LrosUMHdWY9pMZAdN+DOc8QMA0Flv1DJhbt25Ndxbpt03Lu5JS3UZt7nlhD0xjiZLZXPOk0PuJnpNg5oTK2D2xywi3cNcImMIBiBlef5DdpUuXpv0v8hkw6i\/Vg+ykaJF\/x8fHAgETE6l+j9ErLdLLLV8nUIpq7yKtFNfc4yJgchMu1z8Cphz7ZkbWhUwzRmNoNgKjn8g5IWZLrSwdE68sWKvoFAFTRRjqN4IKTP0xymmhubdl9JPC6CIuZ66l7nv0XE3Ns6b+EDA1RaNiWxAwFQcnk2lLG3I5KXyEDodMyZewW2KUEGZlXSFgKgtIreYgYGqNTHq7fKoLnBT+4u7DK32U6NGXALnqS6q9dgiY9mJWxGIETBHsmw0aevszJ4XzoYHJZukaNBBxCcLVVGMETFPhKmcsAqYc+5wjx1YPOCnYoxLLM2eMR++bXO03AxAw\/cY2qWcImKQ4i3YWWm2xGctJYTmECJmiKX5mcHK1nliktgQBk5pop\/0hYNoObArRohPgpOCXD3Dy45SzFTHISbds3wiYsvybGR0B00yozl19yv+Q+kFznBT884FqjD+rHC3J1RxU6+gTAVNHHKq3AgFTfYh2BqautrCElCb2nEjTcAztBe6hxNppj4BpJ1ZFLUXAFMXvNfiWV\/qcFLxCcq7RljGKs7C\/o8jV\/mKqPELA9BvbpJ4hYJLiTNbZFtUWKjDJwnWmSpZ6WS+9lX30iIDpI47WeeiUX1G\/0U3oGQImIcyVXZUSLbrZnBRWBvHTU3xlL0zB61ku9UCu5uVbsncqMCXpNzQ2AqZ8sGpafuCkkC4fYJmOJdXCvCxr6x0BU1tEKrUHAVMmMDVUWzgp5I99TeI0v7fbjoBA3Jb3lqMhYLak3fBYCJhtg1f7CY2TQp58gGt6rjBNz7SWHhEwtUSicjsQMPkDVGu1hQpM\/tjrI9QuXrelsX40BMx6hrX2gICpNTKV2YWAyROQlkSLeZJl82menFC9cuJNwxeOaTjW2AsCpsaoVGgTAiZtUFq\/yuakkDYf5nprPU+2obQ8CrlaQxTy2ICAycO1u14RMOtD2mq1hSWk9bFf2wNCJp4gAiaeXe1HImBqj1Al9iFg4gLRk2hhCSkuB1Iexck4nCbMwpm1cgQCppVIFbYTARMWgN6vmDkphOVDyta951ZKVrIvcjU10Xr6Q8DUE4uqLUHAuMPTa7WFJSR37Eu04MTsRx1OfpxabIWAaTFqBWxGwMxDH\/GKmJNCgR+hZcgRcy+UPLkaSqyd9giYdmJV1FIEzFn8I1VbqMAU\/el5Dc5JevkCg1v+vdKouUYImOZCVsZgBMzHtXT1N\/qEyAmzzO9waVSqMXY65Gp9uZrKIgRMKpKd9zOygOHEcD65OSnU+4MnNuerpaNfcNSbressQ8Cs4zfM0aMJGKoty6nNSbLunz6i+6\/4kKt15+oa6xAwa+gNdOwoAoaJ3y+pOSn4cSrdijhxG3XpHMw5PgImJ92O+u5ZwFBtCU9UTozhzEodMbooJ1dLZV7+cREw+Rl3MUJvAgbRsi4tOSms41fi6FFjNqrfJXJs6zERMFsTb3S8XgTM6FejqdKPk0Iqktv2M2L+k6vb5tiWoyFgtqTd8FgtCxiqLekTj5NCeqZb9jhS\/EbydcscqmEsBEwNUWjAhhYFzIhXm1ulEieFrUjnG2eU3we5mi+HSveMgCkdgUbGb0XAUG3ZJqE4KWzDeYtRehcy5OoWWVRmDARMGe7NjVqzgEG0bJ9OnBS2Z557xF5j2qtfufOhhf4RMC1EqQIbaxQwvV85VhD2WRM4KdQcnXjbevxNkavx+VD7kQiY2iNkse\/t27fi22+\/Fe\/evROXLl0ST548Efv7+7uWDx8+FE+fPp0+P3v2TFy9enX33YsXL8S9e\/emz\/fv3xfXr1\/3IlCLgKHa4hWu7I04KWRHXHSAnuLbky9Fk6LCwREwFQZlyaT379+Lmzdvilu3bk3CRAqS58+fi8ePH4uLFy+KV69eiUePHk2f37x5s\/u3\/E4Knzt37ogHDx5MQ6h\/6+JnbuzSAqbHK8PGUu+MuZwUWo6en+29\/ObIVb94t9gKAdNY1HQRIoWH+VlWX+Tf7du3xYcPH8Tdu3fF4eHhTuy8fPlSHB0dib29PSHbXrlyxasKU0LAUG2pNzk5KdQbm9SWtR7r1u1PHc+e+kPANBZNWwVGiRLpihQsBwcHkyhRAkZ91sWNbGt+XkKxlYBBtLSRkJwU2ohTKitbrsaQq6myoL5+EDD1xcRpkRImv\/76q\/jmm2+maov8MysuSqSoKotZcZHLTycnJ7vjSwqYlidIZ8A6bMBJocOgerjUYtxbtNkjFDQRQiBgGksDtYFX7mORe2D0PS9yWUhfMqpdwFBtaSz5NHM5KbQbu7WWt3axQa6ujXi9xyNg6o2N1TJZNdH3sejLRNeuXWtiCam1CbCxFNnEXE4Km2CuepBWcqAVO6sOdqXGIWAqDcycWUsCRu570ZeJbJt49SWjpU285p6XtXtgqLY0lmgOczkp9BXPWG9auBghV2OjW\/9xCJj6Y3TGQtsSkrwdWj0LJuVt1LpoiREwiJbGkivAXE4KAbAGaFpzPtRs2wCpkdVFBExWvHk6lyLlxo0bU+e5H2QnhYv6Oz4+9nKohasyL0doNEuAkwLJYRKo9XdPrvabqwiYfmOb1DNXBYZqS1Lc1XfGSaH6EBUzsLbcqM2eYoHpcGAETIdBzeHSnICp9aorBwP6\/IsAJwWyYYlATfMCudpvriJg+o1tUs90AUO1JSnaJjvjpNBk2DY3ugYhQ65uHvbNBkTAbIa67YGkgHn9+vXkxOnpadvOYP1qApwUViMcqoOS+VJy7KGCXMBZBEwB6C0NqTbxIl5ailp+Wzkp5Gfc2wilqjHkam+ZpC1ln3I53W90Iz2bu\/NIVWFImUiwHR3GSaGjYG7syta5s\/V4G+McejgqMEOHP875UldScdZyVA4CnBRyUB2nzy3nEHK137xCwPQb26yeUY3Jirf6zjkpVB+iJgzcIo+2GKMJ2B0aiYDpMKhburTlldSWfjHWMgFOCmRIKgK55xByNVWk6usHAVNfTJqziGpMcyFbbTAnhdUI6cAgkCuncvVLAMsTQMCUj0GQBepdSO\/evcv+GoEgw4QQua+kQu2hfT4CnBTysR255xxzCLnab0YhYBqK7fv378XNmzfFrVu3xNWrV4V8M\/Xz58\/F48ePxcWLF0XKFzmuwcKEsYZeG8cS4zbi1KqVKfMrZV+t8uzVbgRMQ5GV1Rf55ukHDx6I\/f19YX5++PDh5M3t27fFhw8fxN27d8Xh4eFO7Lx8+VIcHR2Jvb09IdteuXJFXL9+PQuBHFdSWQyl0ygCnBSisHFQAIFUcwi5GgC9saYImIYCZqvAKFEi3ZCC5eDgYBIlSsCoz7q4kW3Nz7kwMHnkIlu2X+Jalv9Io6\/NtbXHj8S6NV8RMI1FTAmTX3\/9VXzzzTdTtUX+mRUXJVJUlcWsuMjlp5OTk93xOTGkupLKaSN9hxHgpBDGi9brCKyZQ8jVdexrPhoBU3N0DNvUBl65hCT3wOh7XuSykL5kVJOAUW4wkTSUbA5TiWU\/sWzJk5i8izmmJSYj24qAaSj6smqi72PRl4muXbtW5RKSiXfNlVRDoereVE4K3Ye4WgdD5xBytdpQrjYMAbMa4XYdLAkYue9FXyaybeLVl4xyb+J1UQmdhFz98f22BDgpbMub0c4T8J1DyNV+swcB01BsbUtI8q6kJ0+eTHcl1XIbtS9SHoDnS6q+dpwU6ovJqBa5ctH1\/ajcevAbAdNYFKVIuXHjxmT1pUuXduJFuSErK0+fPp0+Pnv2bNoro\/5kBefevXvTx\/v372e7hToUqe+VVGi\/tM9HgJNCPrb0HE5gaQ4hV8N5tnIEAqaVSA1gJxNNO0EmVu3EaiRLbXlJrvabAQiYfmPbpGdUY9oIGyeFNuI0opXmHEKu9psFCJh+Y9u0Z0w6dYeP+NQdH6z7+G6209PT3f\/DpD8CCJj+YtqNR1Rj6g0lAqbe2GDZXwSYQ\/rOBgRM3\/HtwjtOlvWFkZjUFxMsOktAiRf5X2Ulhr\/+CCBg+otplx5xy3VdYUXA1BUPrDlfdfn888\/F8fHx9IWcP+Sf+gyvPgggYPqIY7demBMPJ846Qk0c6ogDVnwkoFdbdOFi8kHI9JUxCJi+4tmNN0sTDeva5cOMgCkfAyz4S7gsiRY49UsAAdNvbLv3TJ5EmbjKhBkBU4Y7o56ttrC3ZeyMQMCMHf\/mvacaUyaECJgy3Ecd1XeJaFQ+o\/qNgBk18p35TTVm24AiYLblPepoSrhQaR01A5b9RsCQF8EE3r9\/L27evCl+\/\/336VjznUul3sdENSY4lNEHIGCi0XGggwC3P5MivgQQML6kaDcR+PDhg7h796747LPPxO3bt4V8Q7Z8I\/aDBw+qeSM2QiZ\/siJg8jMebYTS1RbXhdnSy3DlPPjtt9+Kd+\/eia+++kocHR2Jvb290UK4ub8ImM2Rtz2g\/KH+8MMP0\/8uXrx4zhlZfZF\/UtwosXN4eDi9FVtOAC9fvtz9uGXbK1euZHsrNifZfLkG23xsR+q5lmqLmqsODg6m+ejVq1fThdmTJ0+mCzP9Qk3GR79o04+9du3adIGn+hkpliV8RcCUoN7wmKYI0V0xJwHzsy5u5HHm5xxYqMbkoPrXe2by9E6vPROocUOuqr7cunVrutgyPy9dfNmq0D\/\/\/DNVmA2SGAGzAeSehpA\/5JOTk8mlp0+fTv+v9sCYFRclUlSVxay4qL5ktSb3HxWDtIThmZbnCL2VXiJaYmyrwDx69Eg8fvx4qjQvXXzJao3e1vw8QmxL+YiAKUW+0XHVOrASLXqp9fLly1P5VC0Z1SRgpC1UY9IlHQImHcuee6pliciXsboBwdzHsnTxJedAveLiWmb3tYV2bgIIGDcjWmgEzFLq0vpvDUtItuBxy\/X6lEbArGfYcw81V1ts3NWS0T\/\/+c9pD4y5LISAqTNbETB1xqVaq8yrDXPZSP+h2zbxyuUntWSUexPvEkSqMetSDAGzjl+PR7dWbdFjYFv20ZeNWEKqM2MRMHXGpVqrzM1tS+u\/b968ObM2vLSTv5TDVGPiyCNg4rj1dlTLoiVEwJj79fSLL3PJyLzI6y3mNfmDgKkpGo3Yoj8v4dKlS7tbDZX5pR5kF4uPakw4OQRMOLOejmhticjF3raEJJ\/rIp9vJe9K4jZqF8Ey3yNgynBn1AoJUI3xDwoCxp9VLy3Naot8Y\/zx8XEv7k0iRT2MTjplPmGcB9nVF2oETH0xwaKCBKjG+MFHwPhx6qHV0m9Cihj515OQ6SFmo\/iAgBkl0vgZRIBqzDIuBExQOjXXOHRvS2\/VmOYCNqjBCJhBA4\/bbgJUY+YZIWDc+dNai1DR0pp\/2NsfAQRMfzHFo8QEqMacB4qASZxkBbvrbUNuQZQMvTEBBMzGwBmuTQJUY87GDQHTZh4rq6m2tB0\/rP9IAAFDJkDAg4DarPj69eup9enpqcdR\/TZBwLQXW0RLezHD4mUCCBgyBAIzBJRokV+bd1mMvqyEgGnnZ1NyiUg9jfvXX3+dgN2\/f396VL\/649bkdvKoRksRMDVGBZuaIDDyshICpu4UraXaIh9q+ccff4ijoyMhxczNmzfFrVu3eDhc3enTjHUImGZChaG1EhixGoOAqTMbaxLV8um233\/\/\/fS\/\/f39c8DMF8Oaj+e\/c+fO9CRceSyP568z30pbhYApHQHG74JATSeOLYAiYLag7DdGLdUW01rbCxL1Nrwg0S++tJongIAhOyCQkMAo1RgETMKkiehK5ZncVF7rhnJVNfn73\/8u\/vWvf01e6ntgzLfR6y9MNCsu5gsTI5BxSIcEEDAdBnUkl9QmwYODgzObA0u+UHKEagwCpsyvbGljeRmL5keVIuTGjRs70aLeNaRekIiAqS1i7dmDgGkvZlisEVB3MehXdnrp+s2bN+LRo0fi8ePH4uLFi4tvlU0NtudqDAImdbbM99eSaNG9sC0h6ctGLCFtl0O9joSA6TWyA\/ilNgn++eef4vDwcFeB0SdGVaGR31+9elUsbRzMgazXagwCJke2nO2z9Rcl2pZ99KqLvmQkPTc38f7www9C\/k9eeLCJN3++tTgCAqbFqGHzREBOeF9++aX45ZdfhFpCMpeUzM9LV305sfZWjUHA5MmWVqstNhrmb08KGv3OIv2zPF7\/Tj\/22rVr4u7du7vfeB7y9NoiAQRMi1HD5mkp6KeffhLffffdtMZuChhVcTGv7JbW3XNjLflAsdS+IWDSEe1JtJhUzAfZPXv2bKqEqj8eZJcuj0bsCQEzYtQb91lOinIj4Ndffy0uX7585urMXDKqScAo7D1UYxAw639EtiWi1peN1lOhBwj4E0DA+LOiZSUE5Hr4b7\/9Jm7fvj093VMvL7s+l1pCMtG1Xo1BwMT9GHyrLQiZOL4cNRYBBMxY8e7CW\/0Wad2hb775ZhI1+jKRbRPvycnJ1M6szpSA0+omXwSMf7b4ihb\/HmkJAQhIAggY8qBpArbnwNRyG3UI2NaWlRAw7ujqbzCv9WFzbi9oAYF6CSBg6o0NlnkQqPFBdh5mW5u0VI1BwNijTLUlNvs5DgLhBBAw4cw4AgJZCbRQjUHAnE0B9qxk\/UnQOQTsF32n1DZJDQhUR6D2agwCRgiqLdX9bDBoMAJUYAYLOO62RaDWasyoAqY20WLeVSezm2ertPUbx9p4AgiYeHYcCYFNCNR4y\/VoAqbGDbnqZYnq7juZjDzddpOfJINUQgABU0kgMAMCLgI1VWNGEDC1VVv0\/FAPc\/zPf\/4zPdlWPRZg6V1f5qP8eb+Q6xfH97UTQMDUHiHsg4BGQJ5UX79+LT7\/\/HNxfHxcjE2vAqZm0aIHWwoV+SefaST\/9OcazX023w5te1t0sYRiYAhEEEDAREDjEAhsTcC8y6V0NaY3AVPjEtFcjsm3sMv3f927d0\/8+9\/\/Pidgrly5snszu\/7GZ7PiYntb9NZ5zXgQWEMAAbOGHsdCIDOBpdtzS+6N6UHAtFJtMVNMbtz9xz\/+MS0d2V6NgYDJ\/KOk+2oIIGCqCQWGQCCOQIlqTMsCpqVqi5kR6i3sd+7cEXt7e1YBwxJS3O+Io9ojgIBpL2ZYDIFzBLauxrQmYFqttpiB1m+R1r\/76quvxNHRkfjv\/\/7vaV+M7V1f5pIRm3iZSFongIBpPYLYDwGNwFbVmBYETC+iZSnBzSUkbqNmOhiJAAJmpGjja1IC+luxL126JJ48eSL29\/d3Y+jfP3v2bNqzoP6WHja21sgtqjE1CxhziUh+LnnH1tp4hggY2ZYH2eUkTt81EUDA1BQNbGmGgPm8Dfn5+fPn4vHjx+LixYuihjdi5xQytQkYV7WFdxU189PCUAh4E0DAeKOiIQTmCZgPCdNL++qN2YeHh1MVZulhYzkY51hWqkHAuESLjWXP1ZgcuUOfEKiZAAKm5uhgWzMEdAFz+fJlcffuXXFwcDA9j0MJGPXZduurdFRtvMzhdOpqTEkB0\/JdRDliS58QGJUAAmbUyON3UgJSlPzxxx\/TnSDyTwoYVXGRn+X36vkc+r\/ld\/rDxpIaZeksVTVmawETU23JzZL+IQCBsgQQMGX5M3oHBKQA+fHHH3ebeM0lo5oEjLQlRTVmCwGjixb5+oTT09MOsgUXIACBVAQQMJelUQEAAAVUSURBVKlI0s+QBEzxIiGYS0Y1LCHZgrOmGpNTwLBENORPCachEEwAAROMjAMg8JGAeeeRzkVfJrJt4p172NjWbGOrMakFTOklIvMBcSG3vcv9T99++6149+6dUA+Uk0\/J5Q8CEMhLAAGTly+9d0pA3iYtH+duPvtFuVvDbdQh6EOrMakETA3VFttbmvXY8nC4kEyiLQS2I4CA2Y41I3VEQH9Ine6WfuVe6kF2sZhDqjFrBEzpaouLj3zb882bN8WtW7ect72bt8\/zeH4XXb6HQDoCCJh0LOkJAl0QUNUY6czcE2xDBUxLG3JNAbN027utevPo0aPdAw27SAicgEClBBAwlQYGsyBQkoCrGuMrYGpYIgrlaO5tWrrt3ay4mC9MDB2b9hCAgD8BBIw\/K1pCYDgCc9WYJQFT+xLRUhClILlx44YwlwLVM3zksfpzexAww\/0kcLgiAgiYioKBKRCokYCtGmMKmJaWiOYY28SLbMsSUo1ZiU0QEAIBQxZAAAJeBPRqjHqwXItLRDZnl+4qM5+UrC8pmUtGbOL1SiUaQSAJAQRMEox0AoExCCgRIwXM559\/Lnp4Qq56jsuDBw+mu47MP26jHiO38bI9AgiY9mKGxRAoQkBVW9SdSb282dl8iJ2Ce\/\/+\/ellnPJPb6P\/d\/kdD7Irko4MCgGWkMgBCEBgmYApXPTWS9\/BFQIQgEBOAlRgctKlbwgMQqCXaswg4cJNCHRBAAHTRRhxAgIQgAAEIDAWAQTMWPHGWwhAAAIQgEAXBBAwXYQRJyAAAQhAAAJjEUDAjBVvvIXAjsDSnTVgggAEIFA7AQRM7RHCPghkILD0bJMMw9ElBCAAgeQEEDDJkdIhBOonIKsvL1++FEdHR2Jvb296XL7+vp8UHqi3Ov\/+++\/ib3\/7G29oTgGVPiAAgR0BBAzJAIEBCSy93ycVDn0Mc7xUY9APBCAwLgEEzLixx\/OBCZgVF\/N9P2vRqOrLrVu3psfzm+8MWts\/x0MAAhBAwJADEBiQQG4Bo++x2d\/fnwTMnTt3hHzfkPzMHwQgAIG1BBAwawlyPAQaJJB7CcmsuMiKzPfffz\/9DwHTYMJgMgQqJICAqTAomASB3ATMJaPUm3gRMLkjSP8QgAAChhyAwIAEct9GzRLSgEmFyxDYmAACZmPgDAeBWgjkfJCduWTEJt5aoo4dEOiHAAKmn1jiCQSqIsBt1FWFA2Mg0B0BBEx3IcUhCNRBgAfZ1REHrIBArwQQML1GFr8gAAEIQAACHRNAwHQcXFyDAAQgAAEI9EoAAdNrZPELAhCAAAQg0DEBBEzHwcU1CEAAAhCAQK8EEDC9Rha\/IAABCEAAAh0TQMB0HFxcgwAEIAABCPRKAAHTa2TxCwIQgAAEINAxAQRMx8HFNQhAAAIQgECvBBAwvUYWvyAAAQhAAAIdE0DAdBxcXIMABCAAAQj0SgAB02tk8QsCEIAABCDQMQEETMfBxTUIQAACEIBArwQQML1GFr8gAAEIQAACHRNAwHQcXFyDAAQgAAEI9EoAAdNrZPELAhCAAAQg0DEBBEzHwcU1CEAAAhCAQK8EEDC9Rha\/IAABCEAAAh0TQMB0HFxcgwAEIAABCPRKAAHTa2TxCwIQgAAEINAxAQRMx8HFNQhAAAIQgECvBBAwvUYWvyAAAQhAAAIdE0DAdBxcXIMABCAAAQj0SgAB02tk8QsCEIAABCDQMQEETMfBxTUIQAACEIBArwQQML1GFr8gAAEIQAACHRNAwHQcXFyDAAQgAAEI9EoAAdNrZPELAhCAAAQg0DEBBEzHwcU1CEAAAhCAQK8E\/j8mDjIDLeRtDwAAAABJRU5ErkJggg==","height":420,"width":560}}
%---
