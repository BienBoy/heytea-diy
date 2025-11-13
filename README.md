## 一、Windows 使用教程

### 1. 包含的文件

从 [GitHub Release](https://github.com/BienBoy/heytea-diy/releases) 下载合适的程序 heytea-diy-windows.zip，解压后，目录中应包含：

* `heytea-diy.exe`
* `heytea-diy.ps1`
* `clean.ps1`

### 2. 配置代理

**以管理员身份打开 PowerShell——方法一**

在文件夹上方输入 `powershell` 按回车打开 PowerShell。

![打开powershell](assets/打开powershell.png)

在弹出的终端中输入以下命令，以管理员身份打开 PowerShell：

```powershell
Start-Process PowerShell -Verb RunAs "-noexit -command Set-Location -LiteralPath `"$pwd`""
```

在弹窗中选择是。

![用户权限powershell](assets/用户权限powershell.png)

<div style="color:red">确保终端前面显示的路径是存放程序的文件夹，且窗口标题中有管理员三字！</div>

如果打开失败，可以使用方法二。

**以管理员身份打开 PowerShell——方法二**

点击 Windows 徽标，在搜索框中输入 powershell，并选择以管理员权限打开。

![管理员权限打开powershell](assets/管理员权限打开powershell.png)

打开程序所在文件夹，在地址栏复制文件夹路径。

![复制文件夹路径](assets/复制文件夹路径.png)

在 powershell 中输入命令：

```
cd 复制的内容
```

![切换路径](assets/切换路径.png)

<div style="color:red">确保终端前面显示的路径是存放程序的文件夹，且窗口标题中有管理员三字！</div>

**允许执行本地脚本（如果第一次运行）**

如果从未在这台机器上跑过自定义脚本，可能需要先执行（只需一次）：

```powershell
Set-ExecutionPolicy RemoteSigned
```

根据提示选择 `Y`。

如果还是不能运行脚本，可以使用 Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass 命令临时允许当前会话运行脚本。

![允许执行脚本](assets/允许执行脚本.png)

> 存在此种情况，请手动运行exe文件
<img width="1062" height="98" alt="image" src="https://github.com/user-attachments/assets/d9fdfe3e-a4c8-42a8-bc81-64dcd6d5f10f" />


**运行配置脚本**

在终端中执行：

```powershell
.\heytea-diy.ps1
```

![自动配置](assets/自动配置.png)

脚本支持命名参数 `-p`，例如想使用 **9000 端口**：

```powershell
.\heytea-diy.ps1 -p 9000
```

**验证是否生效**

等待一段时间后，打开浏览器访问：

```text
http://mitm.it
```

能看到 mitmproxy 的提示页面，就说明代理生效。

![mitm.it](assets/mitm.it.png)

---

### 3. 上传杯贴

**准备图片**

将要上传的图片尺寸更改为 **596x832**，转换为 **png** 格式，并确保大小**小于 200KB**。将图片名称改为 **target.png** 并移动到**程序所在目录**。

![图片存放](assets/图片存放.png)

**小程序点击上传**

手机在杯贴自定义页面点击右上角按钮后，点击收藏，以便能够在电脑端打开。

在电脑上打开小程序，进入绘制界面，随便绘制内容，并点击提交。如果配置正确，点击提交创作后，提交的内容已被替换。如下图所示:

<p align="center">
  <img src="assets/手机收藏.png" alt="手机收藏" style="width:30%;" />
  <img src="assets/上传杯贴.png" alt="上传杯贴" style="width:30%;" />
  <img src="assets/成功结果.png" alt="成功结果" style="width:30%;" />
</p>

---

### 4. 关闭代理（重要！！）

当你不再需要代理时，可以执行关闭脚本：

```powershell
.\clean.ps1
```

---

### 5. 常见问题

1. **脚本提示无法执行（ExecutionPolicy 错误）**
   请用管理员 PowerShell 执行一次：

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
   
2. **第一次导入证书时弹出安全提示**
   确认证书颁发者为 `mitmproxy`，并选择允许信任即可。
   
3. **浏览器依旧不走代理**

   * 检查浏览器是否设置了“不要使用系统代理”（特别是 Firefox）。
   * 查看系统代理，观察是否被自动配置
   
4. **程序结束后电脑断网**

   - 参考第 4 步，执行关闭脚本

---

## 二、macOS 使用教程

### 1. 包含的文件

从 [GitHub Release](https://github.com/BienBoy/heytea-diy/releases) 下载合适的程序 heytea-diy-macos-\*.zip，解压后，macOS 目录中应包含：

* `heytea-diy`
* `heytea-diy.sh`
* `clean.sh`

![下载三个文件](assets/下载三个文件.png)

---

### 2. 赋予执行权限（只用一次）

#### 启用“服务”菜单中的「在终端中打开」（若之前没有设置过）

步骤：

1. 打开「系统设置」或「系统偏好设置」

2. 前往：

   ```
   键盘 → 快捷键 → 服务（Services）
   ```

3. 在右侧找到：

   ```
   “文件与文件夹” → ✅ 勾选“在终端中打开”
   ```

![设置打开终端](assets/设置打开终端.png)

#### 使用方式：

1. 打开 Finder
2. 选中你想打开的文件夹（如“应用程序”）
3. **右键 → 服务 → 在终端中打开**

![mac打开终端](assets/mac打开终端.png)

剩下都在这个终端中操作即可。

在文件夹中右键打开终端，输入：

```bash
chmod +x heytea-diy
chmod +x heytea-diy.sh
chmod +x clean.sh  # 如果有的话
```

---

### 3. 配置代理

在终端使用 sudo 运行启动脚本（默认端口 8080）：

```bash
sudo ./heytea-diy.sh
```

![成功案例](assets/成功案例.png)

**验证是否生效**

打开浏览器访问：

```text
http://mitm.it
```

如果能看到页面内容，说明代理已经生效。

如想使用其他端口，如 9000 端口，可使用命名参数：

```bash
sudo ./heytea-diy.sh -p 9000
```

### 4. 上传杯贴

**准备图片**

将要上传的图片尺寸更改为 **596x832**，转换为 **png** 格式，并确保大小**小于 200KB**。将图片名称改为 **target.png** 并移动到**程序所在目录**。

![图片存放](assets/图片存放.png)

**小程序点击上传**

手机在杯贴自定义页面点击右上角按钮后，点击收藏，以便能够在电脑端打开。

在电脑上打开小程序，进入绘制界面，随便绘制内容，并点击提交。如果配置正确，点击提交创作后，提交的内容已被替换。如下图所示:

<p align="center">
  <img src="assets/手机收藏.png" alt="手机收藏" style="width:30%;" />
  <img src="assets/上传杯贴.png" alt="上传杯贴" style="width:30%;" />
  <img src="assets/成功结果.png" alt="成功结果" style="width:30%;" />
</p>

---

### 6. 关闭代理（重要！！）

执行关闭脚本：

```bash
sudo ./clean.sh
```

---

### 7. 常见问题

1. **提示无法打开“因为来自身份不明的开发者”**
	* 第一次运行二进制时，可能需要在「系统设置 → 隐私与安全性」里允许一次。可参考[在 Mac 上安全地打开 App - 官方 Apple 支持 (中国)](https://support.apple.com/zh-cn/102445)设置
2. **证书导入时弹出 GUI 提示**
   * 选择“始终信任” / “总是允许”即可；
   * 如多次弹出，请确认脚本使用的是 System.keychain，而不是登录钥匙串。
3. **程序结束后电脑断网**
   - 参考第 6 步，执行关闭脚本

