function [detp, idNum] = MCXSetRingDetid(detp, center, SDS, SDSWidth)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MCXSetRingDetid 根据SDS重新划分detid
%
%   == 输入参数 ==
%       detp(struct): mcxlab导出的detp
%       center(grid): 中心点坐标
%       SDS(grid): 环形检测器中心的半径
%       SDSWidth(grid): 环形检测器的环宽
%
%   == 输出参数 ==
%       detp: 重新设置detid后的
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pos = detp.p(:, 1:2) - center;
distance = sqrt(pos(:, 1).^2 + pos(:, 2).^2);

if isscalar(SDSWidth)    % 如果仅设置一个SDS宽度
    for i = 1:length(SDS)
        id = (distance >= (SDS(i) - SDSWidth / 2)) & (distance < (SDS(i) + SDSWidth / 2));
        detp.detid(id) = i;
    end
else    % 否则的话，不同SDS具有不同的宽度
    for i = 1:length(SDS)
        id = (distance >= (SDS(i) - SDSWidth(i) / 2)) & (distance < (SDS(i) + SDSWidth(i) / 2));
        detp.detid(id) = i;
    end
end
idNum = length(SDS);

end
