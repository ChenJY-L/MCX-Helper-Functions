function isInMask = getPhotonsInMask(photonCoords, mask)
% 输入:
% photonCoords: N x 2 的矩阵，每行是光子的 (x, y) 坐标
% mask: M x N 的 0-1 图像，定义了掩膜区域

% 将 mask 转换为逻辑矩阵
mask = logical(mask);

% 获取 mask 的大小
[maskHeight, maskWidth] = size(mask);

% 提取光子坐标
x = round(photonCoords(:, 1)); % 取整为整数索引
y = round(photonCoords(:, 2));

% 判断坐标是否在 mask 的有效范围内
isValid = x >= 1 & x <= maskWidth & y >= 1 & y <= maskHeight;

% 初始化结果为 false
isInMask = false(size(photonCoords, 1), 1);

% 仅对有效范围内的光子进行判断
isInMask(isValid) = mask(sub2ind(size(mask), y(isValid), x(isValid)));
end
