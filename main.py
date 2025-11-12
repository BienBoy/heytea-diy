import sys
import os
from mitmproxy.tools.main import mitmdump

def get_addon_script_path() -> str:
    """
    获取 addon_script.py 的真实路径

    - 正常运行：使用当前文件所在目录
    - PyInstaller 单文件模式：使用 sys._MEIPASS
    """
    base_dir = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base_dir, "heytea_addon.py")

def main():
    addon_path = get_addon_script_path()

    # 原始用户参数，去除程序名
    user_args = sys.argv[1:]

    # 传了 -s/--script 就不再使用自带脚本
    has_script = any(arg in ("-s", "--script") for arg in user_args)
    if has_script:
        argv = ["mitmdump", *user_args]
    else:
        # 最前面加上自带脚本，其余参数原样透传
        argv = ["mitmdump", "-s", addon_path, *user_args]

    # 替换 sys.argv
    sys.argv = argv
    mitmdump()

if __name__ == "__main__":
    main()
