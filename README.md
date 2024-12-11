# MCX模拟程序更新日志

## 使用说明

- 直接复制`MCX_Skin7`即可

## 主要功能



## 更新日志

- [Feat] 24/12/10 更新`exportDepth2.m`，支持导出穿透深度和光程数据，并支持导出`traj`文件
- [Feat] 24/12/10 主程序中添加并行控制开关`isuseParfeval`，支持关闭并行导出光能量和光密度

## 函数接口声明

### exportAbsorbance

#### 描述

导出各检测器捕获光子(`detp`)的光能量(`energy`)，吸光度(`absorbance`)和各个介质中的平均光程(`ppath`)。

- 光能量：统计被探测器捕获光子的总体重量（使用Lambert-Beer定律计算）。$w=w_0 \cdot \exp(\sum_{i=0}^n \mu_{a,i} \cdot \rm{pathlength}_i)$
- 吸光度：$A = -ln(\frac{\sum_{detected} w}{w_0})$
- 光程：由MCX直接导出，此处仅计算了加权平均光程。

#### 使用范例

```matlab
[energy, absorbance, ppath] = exportAbsorbance(cfg, detp); % 根据离散检测器导出光能量，吸光度和光程

[energy, absorbance, ppath] = exportAbsorbance(cfg, detp, 'SDS', SDS, 'SDSWidth' SDSWidth); % 根据光子出射位置，计算环形检测器的光能量，吸光度和光程
```

#### 参数

##### 输入参数

- cfg：仿真设置
- detp: 捕获光子结构体
- SDS（可选）: 环半径
- SDSWidth（可选）: 环宽

##### 输出参数

- energy: 各个检测器捕获的光能量
- absorbance：各个检测器捕获的吸光度
- ppath: 各个检测器，在各个介质中的平均光程

### exportDepth2

#### 描述

使用MCX中的replay方法，计算光子的最大穿透深度和加权平均穿透深度。

- 最大穿透深度(`maxDepth`)：各个光子从出射到被捕获整个路径中到达的最大深度
- 加权平均穿透深度(`meanDepth`)：$meanDepth = \rm{mean}(w\cdot z_{max})$
- 各个光子的光程(`outPPath`)：各个光子在不同介质中的光程

#### 使用范例

```Matlab
[maxDepth, meanDepth, outPPath] = exportDepth2(cfg, seeds, detp, thresh);	% 计算离散检测器的深度

[maxDepth, meanDepth, outPPath] = exportDepth2(cfg, seeds, detp, thresh, 'SDS', SDS, 'width', SDSWidth);	% 计算环形检测器的深度
```

#### 参数

##### 输入参数

- cfg：仿真设置
- seeds：捕获光子的随机种子，用于重塑光子的运动路径
- detp: 捕获光子结构体
- thresh：光能量阈值，用于滤除较低能量的光子
- SDS（可选）: 环半径
- SDSWidth（可选）: 环宽

##### 输出参数

- maxDepth: 各光子的最大穿透深度
- meanDepth：各检测器的平均穿透深度
- outPPath：各光子在各介质中的光程
