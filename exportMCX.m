function [energy,absorbance,detPath] = exportMCX( ...
    cfg, detp, detectorType, absorbanceWritePath, ...
    idNums, SDS, SDSWidth, responseWave, wavelength, ...
    isusefakeSDS, isuseresponse, isAngle)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%exportMCX 导出MCX模拟后的仿真结果，并自动写入excel中
%   == 输入参数 ==
%       cfg: 实验设置
%       detp: 检测光子信息
%       detectorType: 设置检测器的类型 
%       absorbanceWritePath: 吸光度导出路径
%       idNums: SDS个数
%       SDS: 环形检测器中心半径
%       SDSWidth: 环形检测器环宽
%       responseWave: 传感器的响应曲线
%       wavelength: 当前仿真波长
%       isusefakeSDS: 是否使用了优化的重叠球检测器
%       isusereponse: 是否使用了传感器响应曲线
%       isAngle: 是否导出光子被探测时的角度信息
%   == 输出参数 ==
%       energy: 每个SDS的光能量
%       absorbance: 每个SDS的吸光度
%       detPath: 每个SDS在不同介质内的光程长
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 通过Detp计算光能量，吸光度，光密度
if strcmp(detectorType, "ring") | strcmp(detectorType, "sphere")
    [energy , absorbance , detPath] = exportAbsorbance(cfg, detp, ...
        'SDS', SDS, 'width', SDSWidth);

elseif strcmp(detectorType, "overlap")
    if isusefakeSDS
        % 修复MCX输出位置错位的bug
        detp.detid = detp.detid.*0 + 1;
        detp.p(:, 1:2) = detp.p(:, 1:2) + [1 1];

        [energy , absorbance , detPath] = exportAbsorbance(cfg, detp, ...
            'SDS', SDS, 'width', SDSWidth);
    else
        [energy , absorbance , detPath] = exportAbsorbance(cfg, detp);
    end

else
    error("Error detector type!")
end

% 考虑响应曲线
if isuseresponse
    response = interp1(responseWave(:,1), responseWave(:,2), wavelength, "spline");
    energy = energy .* response;
end

% 考虑导出光子出射角度
if isAngle && ~isempty(strfind(cfg.savedetflag, 'v'))
    angleEnergy = exportAngle(detp, cfg, SDS, SDSWidth);
    writematrix([NaN(1,90); angleEnergy], absorbanceWritePath, 'WriteMode', 'append', 'Sheet', '角度')
end
% 通过flux导出光密度和光能量
% [ringphotonDensity(:,i), ringphotonEnergy(:,i), numVoxels(:,i)] = exportRingDetectorPhotonDensity(cfg, f, SDS, SDSWidth, 1);

% 写入数据
writematrix(energy, absorbanceWritePath, 'Sheet', '原始光能量', 'WriteMode','append');
writematrix([NaN(1,idNums); detPath], absorbanceWritePath, 'Sheet', '光程', 'WriteMode','append');
% writematrix(ringphotonDensity(:,i)', fluxFilePath, 'WriteMode', 'append','Sheet','光密度');
% writematrix(ringphotonEnergy(:,i)', fluxFilePath, 'WriteMode', 'append','Sheet','光能量');
end