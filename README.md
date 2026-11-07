# tkz-elements 使用手册（中文译本）

_当前版本：**[2026/10/11 version 6.00c]**_

`tkz-elements` 是一个 Lua 库，用于执行定义欧几里得几何图形对象（点、线、圆、圆锥曲线、三角形、路径等）所需的计算。
所有数值计算都在 **Lua** 中完成；绘图由 **tkz-euclide**（推荐）或 **TikZ** 完成。


## 作者: Alain Matthes —— al (dot) ma (at) mac (dot) com


## 中文翻译:  金永权 —— 夏邑县第一高级中学



**本手册可以使用compile-doc.ps1脚本一键生成。**

**使用方法：右键点击本文件，使用PowerShell运行即可。**


## 使用示例
```tex
% !TEX TS-program = lualatex
\documentclass{standalone}
\usepackage[mini]{tkz-euclide}
\usepackage{tkz-elements}
\begin{document}
\directlua{
  init_elements()
  -- 在 Lua 中创建几何对象
  z.A = point(0,0)
  z.B = point(2,0)
  z.C = point(1,1.2)
}
\begin{tikzpicture}
  % 将 Lua 点传输到 TikZ 节点 A、B、C
  \tkzGetNodes
  % 使用 tkz-euclide / TikZ 绘图
  \tkzDrawPolygon(A,B,C)
  \tkzDrawPoints(A,B,C)
  \tkzLabelPoints(A,B,C)
\end{tikzpicture}
\end{document}
```
> 替代方案：使用 `tkzelements` 环境（需要 `luacode`）。