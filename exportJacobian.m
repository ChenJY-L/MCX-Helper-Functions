function exportJacobian(cfg, detp, seeds, slice, savePath, SDS, SDSWidth)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%exportJacobian 导出MCX灵敏度矩阵(Jacobian)
%   Input:
%       cfg: 仿真参数设置
%       detp: 探测光子
%       seeds: 被探测光子种子
%   Output:
%       meanDepth: 平均穿透深度
% MCX中，设置cfg.outputtype = 'jacobian'后，MCX会根据每个光子的随机种子，对光
% 子的传播路径进行复现。并将
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% center = size(cfg.vol,[1,2])/2;
SDS = SDS./cfg.unitinmm;
SDSWidth = SDSWidth/cfg.unitinmm;                                 
[detp, idx] = MCXSetRingDetid(detp, center, SDS, SDSWidth);

% idx = find(cfg.detpos(:,4)>0);

for i = 1:idx
    index = detp.detid == i;
    newcfg = cfg;
    newcfg.respin = 1;
    newcfg.seed = seeds.data(:,index);
    newcfg.outputtype = 'jacobian';
    newcfg.detphotons = detp.data(:,index);
    % newcfg.replaydet = -1;      % replay全部detector
    flux = mcxlab(newcfg);

    tmp = squeeze(flux.data(:, slice, :));
    saveFileName = sprintf('%s-%d.mat',savePath, i);
    save(saveFileName, "tmp")
end

end