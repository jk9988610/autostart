# -*- coding: utf-8 -*-
"""弹窗自动关闭测试：验证 show_popup 能正常构建渲染，1.2 秒后自动关闭。"""
import importlib.util
import tkinter as tk

spec = importlib.util.spec_from_file_location("dl", r"E:\tools\autostart\daily-launcher.py")
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

_orig_mainloop = tk.Tk.mainloop


def _auto_mainloop(self, *a, **k):
    self.after(1200, self.destroy)
    return _orig_mainloop(self, *a, **k)


tk.Tk.mainloop = _auto_mainloop

r = m.show_popup(
    "启动器 - 测试",
    ["✅ 测试项", "❌ 失败项", "", "完成：成功 1 / 共 2", "日志: launcher.log"],
)
print("popup ok, action =", r)
