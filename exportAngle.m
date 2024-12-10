function energyBin = exportAngle(detp,cfg,SDS,SDSWidth)

SDS = SDS./cfg.unitinmm;
SDSWidth = SDSWidth/cfg.unitinmm;

% 重新计算detid
center = size(cfg.vol,[1,2])/2; % 计算中心点坐标 (是否需要+0.5?)

pos = detp.p(:,1:2) - center;
distance = sqrt(pos(:,1).^2 + pos(:,2).^2);

for i = 1:length(SDS)
    id = (distance >= (SDS(i) - SDSWidth/2)) & (distance < (SDS(i) + SDSWidth/2));
    detp.detid(id) = i;
end
idNum = length(SDS);

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