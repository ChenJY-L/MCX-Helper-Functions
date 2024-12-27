function energyBin = exportAngle(detp,cfg,varargin)
%% 设置输入检测
p = inputParser;
addRequired(p, 'cfg');
addRequired(p, 'detp');
addOptional(p, 'SDS', [1.7, 2.0, 2.3, 2.6, 2.9]);
addOptional(p, 'width', 0.2);
parse(p, cfg, detp, varargin{:});
%% 处理环形检测器
if ~isempty(varargin)
    SDS = p.Results.SDS / cfg.unitinmm;
    SDSWidth = p.Results.width / cfg.unitinmm;

    % 重新计算detid
    center = size(cfg.vol,[1,2])/2; % 计算中心点坐标 (是否需要+0.5?)

    [detp, idNum] = MCXSetRingDetid(detp,center,SDS,SDSWidth);
else
    idNum = size(cfg.detpos, 1);
end

%% 导出角度分布
num = zeros(idNum,90);
energyBin = zeros(idNum,90);

% 弧度2角度
zAngle = detp.v(:,3);
zAngle = rad2deg(acos(zAngle));
zAngle = 180-zAngle;
zAngle = fix(zAngle);

detWeight = mcxdetweight(detp, cfg.prop, cfg.unitinmm);
for j = 1:idNum
    det = detp.detid == j;
    for i = 1:90
        num(j,i) = size(find(zAngle(det)==(i-1)),1);
        energyBin(j,i) = sum(detWeight(zAngle(det)==(i-1)));
    end
end
end