a = Analysis(
    ['main.py'],
    datas=[
        ('heytea_addon.py', '.')
    ],
    hiddenimports=['requests_toolbelt'],
    excludes=['mitmproxy.tools.web', 'mitmproxy.tools.console'],
    optimize=0,
)
pyz = PYZ(a.pure, a.zipped_data)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [('unbuffered', None, 'OPTION')],
    name='heytea-diy',
    icon='heytea.ico',
    console=True,
    entitlements_file=str('macos-entitlements.plist')
)

