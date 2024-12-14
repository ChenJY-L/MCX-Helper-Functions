function exportJacobian(cfg, detp, seeds, slice, savePath, SDS, SDSWidth, outputtype)
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

if nargin < 8
    outputtype = 'jacobian'; % 默认设为'jacobian'
end

SDS = SDS./cfg.unitinmm;
SDSWidth = SDSWidth/cfg.unitinmm;
center = size(cfg.vol, [1 2]);
[detp, idx] = MCXSetRingDetid(detp, center, SDS, SDSWidth);

for i = 1:idx
    index = detp.detid == i;
    newcfg = cfg;
    newcfg.respin = 1;
    newcfg.seed = seeds.data(:, index);
    newcfg.outputtype = outputtype; % 使用变量outputtype
    newcfg.detphotons = detp.data(:, index);
    
    flux = mcxlab(newcfg);

    tmp = squeeze(flux.data(:, slice, :));
    saveFileName = sprintf('%s-%d.mat', savePath, i);
    save(saveFileName, "tmp")
end

end
