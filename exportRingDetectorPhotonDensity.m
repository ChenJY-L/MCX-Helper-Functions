function [photonDensity, photonEnergy, numVoxels] = exportRingDetectorPhotonDensity(cfg, f, SDS, width, zlayer)
%%
%
%  MCX光密度导出程序
%   # cfg: 仿真配置结构体
%   # flux: 仿真导出的光通量，默认已经去掉了时间维度。即flux包含xyz三个维度。
%   # SDS: 探测器位置，可设置为一个数组。单位为mm
%   # width: 环宽度(默认内环半径=SDS-width/2,外环半径=SDS+width/2)。单位为mm
%   # zlayer: 提取光密度层的z轴坐标
%   光密度计算公式: \phi = sum(w)/nphoton/ds/n

flux = f.data;
nomalizer = f.stat.normalizer;
[m, n, c] = size(flux);

% 创建网格
[xx, yy] = meshgrid(1:m, 1:n);

% 转换单位
SDS = SDS ./ cfg.unitinmm;
width = width / cfg.unitinmm;

photonDensity = zeros(1, length(SDS));
photonEnergy = zeros(1, length(SDS));
numVoxels = zeros(1, length(SDS));

flux = flux(:, :, zlayer);
for i = 1:length(SDS)
    area = extractPoints(xx - 0.5, yy - 0.5, [m / 2, n / 2], SDS(i) - width / 2, SDS(i) + width / 2);
    %     photonDensity(i) = sum(sum(flux(area))) / sum(sum(area)) ...
    %                         / cfg.nphoton / (cfg.unitinmm^2);
    numVoxels(i) = sum(sum(area));
    photonDensity(i) = sum(sum(flux(area))) / sum(sum(area));
    photonEnergy(i) = sum(sum(flux(area))) / nomalizer;
end

end

function out = extractPoints(X, Y, center, r1, r2)
% 计算每个网格点到中心点的距离
distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);

% 提取距离在 r1 和 r2 之间的网格点
out = distances >= r1 & distances <= r2;

end
