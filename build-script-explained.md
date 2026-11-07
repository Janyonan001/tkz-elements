第 1–4 行：声明脚本参数
```powershell
param(
  [string]$WorkDir = "F:\tkz-elements-main\doc\latex",
  [int]$Passes = 3
)
```
`param(...)` 是 PowerShell 脚本/函数声明参数的语法块，必须放在脚本最前面（注释之外）。

`[string]$WorkDir = "..."`：定义一个字符串参数 `$WorkDir`，默认值是文档所在目录。调用时可覆盖，如 `.\build.ps1 -WorkDir "D:\other"`。

`[int]$Passes = 3`：定义一个整数参数 $Passes，默认 3，表示 LaTeX 编译几遍。[int] 限定类型，传 "abc" 会转换失败报错，比裸变量安全。

这两个参数让脚本可复用：换目录、改编译遍数都不用改脚本正文。

第 5–6 行：设置 TeX 的搜索路径环境变量
```powershell
$env:TEXINPUTS = "F:\tkz-elements-main\latex;"
$env:LUAINPUTS = "F:\tkz-elements-main\latex;"
```
`$env:XXX` 是 PowerShell 访问进程级环境变量的写法，只影响当前进程及其子进程（即后面启动的 lualatex、makeindex），不会永久改系统环境变量。

`TEXINPUTS`：TeX 引擎查找 .tex、.sty、.cls 等输入文件的目录列表。

`LUAINPUTS`：LuaTeX 查找 Lua 模块（.lua 文件）的目录列表。

两个变量都指向 `F:\tkz-elements-main\latex`（tkz-elements 源码目录），让引擎能找到尚未安装到 TeX 发行版的源文件。

末尾的分号 `;` 很关键：Windows 版 TeX 用 `;` 分隔路径，末尾留 `;` 表示"这个目录之后继续搜索默认路径"。不写末尾分号会只在该目录找，导致找不到 article.cls 等标准宏包而失败。

注意：这里是覆盖而非追加，LUAINPUTS 默认值被丢弃。多数情况够用，但更稳妥是追加。

第 7 行：切换当前工作目录
```powershell
Push-Location $WorkDir
```
`Push-Location` 把当前目录压入内部栈，然后 `Set-Location` 到 `$WorkDir`。

为什么用 `Push-Location` 而非 `cd`：它成对配 `Pop-Location`，能在结束时精确恢复到调用前的目录，即使中途出错。

后续 `lualatex TKZdoc-elements-main.tex` 是相对路径，所以必须先切到该目录。

第 8 行：开始异常保护块
```powershell
try {
  Write-Host "=== Pass 1 start: $(Get-Date -Format 'HH:mm:ss') ==="
  & lualatex -interaction=nonstopmode -file-line-error TKZdoc-elements-main.tex
  Write-Host "pass1 exit=$LASTEXITCODE  $(Get-Date -Format 'HH:mm:ss')"
  if (Test-Path -LiteralPath "TKZdoc-elements-main.idx") {
    & makeindex -q TKZdoc-elements-main.idx
    Write-Host "makeindex exit=$LASTEXITCODE"
  }
  for ($i = 2; $i -le $Passes; $i++) {
    Write-Host "=== Pass $i start: $(Get-Date -Format 'HH:mm:ss') ==="
    & lualatex -interaction=nonstopmode -file-line-error TKZdoc-elements-main.tex
    Write-Host "pass$i exit=$LASTEXITCODE  $(Get-Date -Format 'HH:mm:ss')"
  }
  Write-Host "=== ALL DONE $(Get-Date -Format 'HH:mm:ss') ==="
}
 finally {
  Pop-Location
}
```
 保证无论是否抛异常，finally 里的清理代码都执行。

这里唯一要保护的资源是"当前目录状态"，清理动作是 Pop-Location。

第 9 行：打印第一遍开始时间
```powershell
  Write-Host "=== Pass 1 start: $(Get-Date -Format ''HH:mm:ss'') ==="
```
Write-Host 直接往控制台输出（不进入管道），适合做进度提示。

`$(...)` 是子表达式，先执行里面的命令再把结果嵌进字符串。

`Get-Date -Format 'HH:mm:ss'` 取当前时间，格式化成时:分:秒。编译耗时可能几十秒到几分钟，时间戳便于看哪一遍慢。

循环从第 2 遍开始，所以第 1 遍单独写在这里，不在 for 里。

第 10 行：第一遍编译
```powershell
  & lualatex -interaction=nonstopmode -file-line-error TKZdoc-elements-main.tex
```
`&` 是调用运算符（call operator），后面跟可执行文件名，让 PowerShell 把它当外部程序执行（更显式、可读）。

`lualatex`：LuaLaTeX 引擎，支持 Lua 脚本，tkz-elements 需要它。

`-interaction=nonstopmode`：遇到错误不暂停等待输入，尽量继续编译。适合自动化，否则出错会卡住等人按键。

`-file-line-error`：错误信息格式改为 文件:行号: 错误，方便定位。

`TKZdoc-elements-main.tex`：要编译的主文件（相对路径，依赖第 7 行切好的目录）。

这一行会生成 `.aux`、`.toc`、`.idx`、`.log`、`.pdf` 等文件。

第 11 行：报告第一遍结果
```powershell
  Write-Host "pass1 exit=$LASTEXITCODE  $(Get-Date -Format ''HH:mm:ss'')"
```
`$LASTEXITCODE`：自动变量，保存最近一次外部程序的退出码。0 成功，非 0 表示有错误。

把退出码插进字符串打印，再跟结束时间戳，配合第 9 行算出这一遍耗时。

这里只是打印，不据此中断脚本——即使第一遍失败，后面还会继续跑。原脚本的小缺陷，可用 `if ($code -ne 0) { break }` 改进。

第 12 行：检查索引文件是否存在
```powershell
  if (Test-Path -LiteralPath "TKZdoc-elements-main.idx") {
```
`Test-Path` 判断路径是否存在，返回 $true/$false。

`-LiteralPath`：把参数当作字面路径处理，不解释通配符（*、?、[）。文件名有特殊字符时更安全。

`.idx` 是 LaTeX 在第一遍编译遇到 `\index{...} / \printindex` 时生成的索引条目原始文件。没有索引就不会生成，所以先判断。

只在第一遍后判断：`.idx `在第一遍就写好；后续遍数主要把 `makeindex` 生成的 `.ind `读进来、让页码/交叉引用稳定，通常不需要重新生成索引。

第 13 行：生成索引
```powershell
    & makeindex -q TKZdoc-elements-main.idx
```
`makeindex`：处理 `.idx` 文件，排序整理后生成 `.ind`（供 LaTeX \printindex 读入）和 `.ilg`（日志）。

`-q：quiet`，安静模式，少打印无关信息。

输入是 `TKZdoc-elements-main.idx`，输出默认同名 `.ind`。

这步必须在第一遍 LaTeX 之后（.idx 由 LaTeX 生成），且在下一遍 LaTeX 之前（下一遍要把 .ind 读进去排版索引页）。

第 14 行：报告 makeindex 结果
```powershell
    Write-Host "makeindex exit=$LASTEXITCODE"
```
同样用 `$LASTEXITCODE` 看 makeindex 是否成功，0 成功。

`$LASTEXITCODE` 每次调用外部程序都会被覆盖，必须紧跟在 `& makeindex` 之后读。

第 15 行：结束 if 块
```powershell
  }
```
第 16 行：从第 2 遍开始循环编译
```powershell
  for ($i = 2; $i -le $Passes; $i++) {
```
C 风格 for 循环：$i 从 2 开始，`$i -le $Passes`（PowerShell 用 -le 而非 <=）时继续，每轮 `$i++`。

为什么从 2 开始：第 1 遍已单独处理（并在其后跑了 makeindex）。第 2、3 遍是为了让目录（.toc）、交叉引用（.aux）、索引页码（.ind）稳定下来——LaTeX 经典的多遍编译机制。

若 $Passes = 3，循环跑 $i = 2, 3，总共编译 3 遍。若 $Passes = 1，循环一次不跑，只编译 1 遍（但 makeindex 仍执行）。

第 17 行：打印本遍开始时间
```powershell
    Write-Host "=== Pass $i start: $(Get-Date -Format ''HH:mm:ss'') ==="
```
和第一遍那行同构，只是 $i 是变量，会显示当前遍数。

第 18 行：再编译一遍
```powershell
    & lualatex -interaction=nonstopmode -file-line-error TKZdoc-elements-main.tex
```
参数与第 10 行完全相同。这一遍会读取上一遍生成的 `.aux`、`.toc`、`.ind`，更新页码、目录、引用，并重新写出新的这些文件。

第 19 行：报告本遍结果
```powershell
    Write-Host "pass$i exit=$LASTEXITCODE  $(Get-Date -Format ''HH:mm:ss'')"
```
`pass$i` 里的 $i 会展开成数字，如 pass2、pass3。

打印退出码和结束时间戳。同样只是打印，不据此中断。

第 20 行：结束 for 循环
```powershell
  }
```
第 21–24 行：结束 try 并恢复目录
```powershell
}
finally {
  Pop-Location
}
```
} 关闭 try 块。

`finally { Pop-Location }`：无论 try 正常结束还是抛异常，都会执行 `Pop-Location`，把当前目录弹栈恢复到调用脚本前的目录。

这是 Push-Location 的正确配对用法，防止脚本跑完把用户 shell 的当前目录"留在" `F:\tkz-elements-main\doc\latex`。

整体流程总结
接收工作目录和编译遍数两个参数（带默认值）。

把 tkz-elements 源码目录加入 TeX 的 .tex 和 .lua 搜索路径。

切到文档目录，用 try/finally 保证事后切回。

第 1 遍 lualatex → 生成 .idx 等辅助文件。

若存在 .idx，跑 makeindex 生成 .ind。

循环再跑 Passes - 1 遍 lualatex，让目录/引用/索引页码收敛。

每遍打印开始/结束时间戳和退出码；目录最终恢复。

可以改进的点
`LUAINPUTS/TEXINPUTS` 用追加而非覆盖，避免丢默认路径。

检查 $LASTEXITCODE，非 0 时 break 或 throw，别闷头编译到底。

Push-Location 前先 Test-Path 校验目录存在，否则 finally 里的 Pop-Location 可能弹空栈报错。

若索引页码在后续遍数变化，可在每遍后按需重跑 makeindex（多数文档不必）。
'@

Set-Content -LiteralPath 
out File −Value
outFile−Valuecontent -Encoding UTF8
Write-Host "已生成: $outFile"

text

说明：

- 用 `Set-Content -Encoding UTF8` 写入，中文不会乱码（PowerShell 5.1 的 `UTF8` 带 BOM，某些 Markdown 渲染器能正常识别；若想无 BOM，可用 `[IO.File]::WriteAllText($outFile, $content, [Text.UTF8Encoding]::new($false))`）。
- `@' ... '@` 是**单引号 here-string**，内部不解析变量、不解释 `$`，正好适合放含 `$LASTEXITCODE` 的脚本文本；其中 `'HH:mm:ss'` 的单引号在 here-string 内写成了 `''`（PowerShell 字符串内转义单引号的方式），因为外层用的是单引号 here-string，内部单引号需双写。
- 文件最终保存为 `F:\tkz-elements-main\doc\build-script-explained.md`。

如果你希望我直接给出文件内容（你自己粘贴保存），或改成无 BOM、或把文件名/标题改一下（比如加日期），告诉我即可。