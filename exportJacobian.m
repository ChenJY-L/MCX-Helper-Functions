function exportJacobian(cfg, detp, seeds, slice, savePath, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exportJacobian 导出MCX灵敏度矩阵(Jacobian)
%   Input:
%       cfg: 仿真参数设置
%       detp: 探测光子
%       seeds: 被探测光子种子
%       slice: 切片位置
%       savePath: 文件保存路径
%       SDS: 探头位置
%       SDSWidth: 探头宽度
%       outputtype: (optional) 设置cfg.outputtype的参数
%   Output:
%       meanDepth: 平均突透深度
% 
% MCX中，设置cfg.outputtype = 'jacobian'后，MCX会根据每个光子的随机种子，对光
% 子的传播路径进行复现。并将
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 设置输入检测
p = inputParser;
addRequired(p, 'cfg');
addRequired(p, 'detp');
addOptional(p, 'SDS', [1.7, 2.0, 2.3, 2.6, 2.9]);
addOptional(p, 'width', 0.2);
addOptional(p, 'outputtype', 'jacobian');
addOptional(p, 'isSlice', true);
parse(p, cfg, detp, varargin{:});

isSlice = p.Results.isSlice;
outputtype = p.Results.outputtype;
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

for i = 1:idNum
    index = detp.detid == i;
    newcfg = cfg;
    newcfg.respin = 1;
    newcfg.seed = seeds.data(:, index);
    newcfg.outputtype = outputtype; % 使用变量outputtype
    newcfg.detphotons = detp.data(:, index);
    
    flux = mcxlab(newcfg);
    
    if isSlice
        tmp = squeeze(flux.data(:, slice, :));
    else
        tmp = flux.data;
    end
    saveFileName = sprintf('%s-%g.mat', savePath, i);
    save(saveFileName, "tmp")
end

end
