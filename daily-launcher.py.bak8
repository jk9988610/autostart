#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""可配置的日常启动器：按 profile 打开一组程序/文件/目录/网址，并输出启动报告。
支持 --gui 图形化配置。"""

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
CONFIG_FILE = BASE_DIR / "launch-config.json"
LOG_FILE = BASE_DIR / "launcher.log"
UI_STATE_FILE = BASE_DIR / "ui-state.json"


def load_ui_state():
    if UI_STATE_FILE.exists():
        try:
            with open(UI_STATE_FILE, encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def save_ui_state(state):
    try:
        with open(UI_STATE_FILE, "w", encoding="utf-8") as f:
            json.dump(state, f, ensure_ascii=False, indent=2)
    except Exception:
        pass


def center_window(root, w, h):
    root.update_idletasks()
    sw = root.winfo_screenwidth()
    sh = root.winfo_screenheight()
    x = max(0, (sw - w) // 2)
    y = max(0, (sh - h) // 2)
    root.geometry(f"{w}x{h}+{x}+{y}")


def log(msg, also_print=True):
    line = f"{datetime.now():%Y-%m-%d %H:%M:%S} | {msg}"
    if also_print:
        print(line)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass


def load_config():
    if not CONFIG_FILE.exists():
        print(f"配置文件不存在: {CONFIG_FILE}")
        sys.exit(1)
    with open(CONFIG_FILE, encoding="utf-8") as f:
        return json.load(f)


def save_config(config):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=2)


def resolve_opener(item, config):
    opener = item.get("opener")
    if not opener:
        return None
    return config.get("openers", {}).get(opener, opener)


def launch_item(item, config):
    itype = item.get("type", "file")
    path = item.get("path", "")
    name = item.get("name") or Path(path).name or path
    args = list(item.get("args", []))

    try:
        if itype != "url" and not Path(path).exists():
            return name, False, f"路径不存在: {path}"

        opener = resolve_opener(item, config)

        if itype == "url":
            if opener:
                subprocess.Popen([opener, path])
            else:
                os.startfile(path)
        else:
            if opener:
                subprocess.Popen([opener] + args + [path])
            else:
                os.startfile(path)
        return name, True, ""
    except Exception as e:
        return name, False, str(e)


def show_popup(title, lines):
    if sys.platform != "win32":
        return
    try:
        import tkinter as tk
        from tkinter import messagebox
        root = tk.Tk()
        root.withdraw()
        messagebox.showinfo(title, "\n".join(lines))
        root.destroy()
    except Exception as e:
        log(f"弹窗失败: {e}", also_print=False)


def run_gui(config):
    import tkinter as tk
    from tkinter import ttk, filedialog, messagebox, simpledialog

    root = tk.Tk()
    root.withdraw()
    root.title("启动清单配置")

    _ui = load_ui_state()
    _w = _ui.get("window", {}).get("width", 1020)
    _h = _ui.get("window", {}).get("height", 660)
    _x = _ui.get("window", {}).get("x")
    _y = _ui.get("window", {}).get("y")
    if _x is not None and _y is not None:
        root.geometry(f"{_w}x{_h}+{_x}+{_y}")
    else:
        center_window(root, _w, _h)
    root.minsize(900, 540)

    style = ttk.Style()
    style.configure("Treeview", rowheight=32)
    style.configure("Treeview.Heading", padding=(0, 8), font=("Microsoft YaHei UI", 10, "bold"))

    profiles = config.setdefault("profiles", {})
    openers = config.setdefault("openers", {})

    state = {"profile": None, "items": [], "sel_index": None, "_syncing": False}

    # ---------- 顶部 ----------
    top = ttk.Frame(root, padding=8)
    top.pack(fill="x")
    ttk.Label(top, text="配置档:").pack(side="left")
    profile_var = tk.StringVar()
    profile_combo = ttk.Combobox(top, textvariable=profile_var, values=list(profiles.keys()),
                                 state="readonly", width=18)
    profile_combo.pack(side="left", padx=(4, 8))

    def load_profile(name):
        state["profile"] = name
        state["items"] = [dict(x) for x in profiles.get(name, {}).get("items", [])]
        state["sel_index"] = None
        refresh_tree()
        clear_form()

    def on_profile_change(event=None):
        if profile_var.get():
            load_profile(profile_var.get())

    profile_combo.bind("<<ComboboxSelected>>", on_profile_change)

    def new_profile():
        name = simpledialog.askstring("新建配置档", "名称（英文，如 work2）:")
        if not name or not name.strip():
            return
        name = name.strip()
        if name in profiles:
            messagebox.showwarning("已存在", f"配置档 {name} 已存在")
            return
        profiles[name] = {"name": name, "items": []}
        profile_combo["values"] = list(profiles.keys())
        profile_var.set(name)
        load_profile(name)

    ttk.Button(top, text="新建配置档", command=new_profile).pack(side="left")

    # ---------- 列表 ----------
    mid = ttk.Frame(root, padding=(8, 0))
    # mid.pack 已移至 bottom_bar 之后（见下方）
    columns = ("type", "name", "path", "opener")
    tree = ttk.Treeview(mid, columns=columns, show="headings", height=16)
    tree.heading("type", text="类型")
    tree.heading("name", text="名称")
    tree.heading("path", text="路径 / URL")
    tree.heading("opener", text="打开方式")
    _cols = _ui.get("columns", {})
    tree.column("type", width=_cols.get("type", 70), anchor="center")
    tree.column("name", width=_cols.get("name", 150))
    tree.column("path", width=_cols.get("path", 560))
    tree.column("opener", width=_cols.get("opener", 130), anchor="center")

    vsb = ttk.Scrollbar(mid, orient="vertical", command=tree.yview)
    tree.configure(yscrollcommand=vsb.set)
    tree.pack(side="left", fill="both", expand=True)
    vsb.pack(side="right", fill="y")

    def refresh_tree():
        tree.delete(*tree.get_children())
        for i, it in enumerate(state["items"]):
            tree.insert("", "end", iid=str(i), values=(
                it.get("type", "file"),
                it.get("name", ""),
                it.get("path", ""),
                it.get("opener", ""),
            ))

    # ---------- 底部固定区（表单 + 按钮）----------
    bottom_bar = ttk.Frame(root)
    bottom_bar.pack(side="bottom", fill="x")

    mid.pack(side="top", fill="both", expand=True)
    # ---------- 表单 ----------
    form = ttk.LabelFrame(bottom_bar, text="编辑项（选中行后改表单会实时保存；新增请先「清空」再填）", padding=8)
    form.pack(fill="x", padx=8, pady=(8, 4))

    type_var = tk.StringVar(value="folder")
    name_var = tk.StringVar()
    path_var = tk.StringVar()
    opener_var = tk.StringVar(value="(默认)")
    args_var = tk.StringVar()

    row1 = ttk.Frame(form)
    row1.pack(fill="x", pady=2)
    ttk.Label(row1, text="类型:").pack(side="left")
    type_combo = ttk.Combobox(row1, textvariable=type_var,
                 values=["app", "file", "folder", "url"], state="readonly", width=10)
    type_combo.pack(side="left", padx=(4, 16))
    ttk.Label(row1, text="名称:").pack(side="left")
    ttk.Entry(row1, textvariable=name_var, width=32).pack(side="left", padx=4)

    row2 = ttk.Frame(form)
    row2.pack(fill="x", pady=2)
    ttk.Label(row2, text="路径:").pack(side="left")
    ttk.Entry(row2, textvariable=path_var).pack(side="left", fill="x", expand=True, padx=4)

    def browse_path():
        t = type_var.get()
        if t == "folder":
            p = filedialog.askdirectory(title="选择文件夹")
        elif t in ("file", "app"):
            p = filedialog.askopenfilename(title="选择文件")
        else:
            messagebox.showinfo("提示", "URL 类型请直接输入网址")
            return
        if p:
            path_var.set(p)
            if not name_var.get().strip():
                name_var.set(Path(p).name)

    ttk.Button(row2, text="浏览...", command=browse_path, width=8).pack(side="left")

    row3 = ttk.Frame(form)
    row3.pack(fill="x", pady=2)
    ttk.Label(row3, text="打开方式:").pack(side="left")

    def opener_values():
        return ["(默认)"] + sorted(openers.keys()) + ["(浏览选择 exe...)"]

    opener_combo = ttk.Combobox(row3, textvariable=opener_var, values=opener_values(),
                                state="readonly", width=30)
    opener_combo.pack(side="left", padx=4)

    ttk.Label(row3, text="参数(逗号分隔):").pack(side="left", padx=(16, 0))
    ttk.Entry(row3, textvariable=args_var, width=28).pack(side="left", padx=4)

    # ---------- 保存与实时同步 ----------
    def _persist():
        if state["profile"] is None:
            return False
        try:
            profiles[state["profile"]]["items"] = [dict(x) for x in state["items"]]
            save_config(config)
            return True
        except Exception as e:
            log(f"保存配置失败: {e}")
            return False

    def _sync_selected(*_):
        if state.get("_syncing") or state["sel_index"] is None:
            return
        idx = state["sel_index"]
        if idx >= len(state["items"]):
            return
        it = state["items"][idx]
        it["type"] = type_var.get()
        p = path_var.get()
        it["name"] = name_var.get().strip() or Path(p).name or p
        it["path"] = p
        op = opener_var.get()
        if op and op not in ("(默认)", "(浏览选择 exe...)"):
            it["opener"] = op
        else:
            it.pop("opener", None)
        a = args_var.get().strip()
        if a:
            it["args"] = [x.strip() for x in a.split(",") if x.strip()]
        else:
            it.pop("args", None)
        if str(idx) in tree.get_children():
            tree.item(str(idx), values=(
                it.get("type", "file"), it.get("name", ""),
                it.get("path", ""), it.get("opener", ""),
            ))
        _persist()

    def on_opener_change(event=None):
        v = opener_var.get()
        if v == "(浏览选择 exe...)":
            p = filedialog.askopenfilename(
                title="选择用来打开的可执行文件",
                filetypes=[("可执行文件", "*.exe"), ("所有文件", "*.*")],
            )
            if not p:
                restore = "(默认)"
                if state["sel_index"] is not None and state["sel_index"] < len(state["items"]):
                    restore = state["items"][state["sel_index"]].get("opener") or "(默认)"
                opener_var.set(restore)
                return
            key = Path(p).stem.lower()
            base = key
            n = 2
            while key in openers and openers[key].lower() != p.lower():
                key = f"{base}{n}"
                n += 1
            openers[key] = p
            save_config(config)
            opener_combo["values"] = opener_values()
            opener_var.set(key)
        _sync_selected()

    opener_combo.bind("<<ComboboxSelected>>", on_opener_change)
    type_combo.bind("<<ComboboxSelected>>", _sync_selected)
    for _v in (name_var, path_var, args_var):
        _v.trace_add("write", _sync_selected)

    # ---------- 操作按钮 ----------
    btns = ttk.Frame(bottom_bar)
    btns.pack(fill="x", padx=8, pady=(0, 8))

    def clear_form():
        state["sel_index"] = None
        state["_syncing"] = True
        type_var.set("folder")
        name_var.set("")
        path_var.set("")
        opener_var.set("(默认)")
        args_var.set("")
        state["_syncing"] = False
        for iid in tree.selection():
            tree.selection_remove(iid)

    def form_to_item():
        path = path_var.get().strip()
        name = name_var.get().strip() or Path(path).name or path
        item = {"type": type_var.get(), "name": name, "path": path}
        op = opener_var.get()
        if op and op not in ("(默认)", "(浏览选择 exe...)"):
            item["opener"] = op
        a = args_var.get().strip()
        if a:
            item["args"] = [x.strip() for x in a.split(",") if x.strip()]
        return item

    def add_new():
        if state["sel_index"] is not None:
            messagebox.showinfo("提示", "当前选中项已自动同步。\n要新增请先点「清空」取消选中。")
            return
        if not path_var.get().strip():
            messagebox.showwarning("提示", "路径不能为空")
            return
        state["items"].append(form_to_item())
        refresh_tree()
        clear_form()
        _persist()

    def delete_selected():
        sel = tree.selection()
        if not sel:
            return
        idx = int(sel[0])
        if messagebox.askyesno("确认", f"删除: {state['items'][idx].get('name')} ?"):
            state["items"].pop(idx)
            refresh_tree()
            clear_form()
            _persist()

    def move(delta):
        sel = tree.selection()
        if not sel:
            return
        idx = int(sel[0])
        ni = idx + delta
        if 0 <= ni < len(state["items"]):
            state["items"][idx], state["items"][ni] = state["items"][ni], state["items"][idx]
            refresh_tree()
            tree.selection_set(str(ni))
            state["sel_index"] = ni
            _persist()

    def on_tree_select(event=None):
        sel = tree.selection()
        if not sel:
            return
        idx = int(sel[0])
        it = state["items"][idx]
        state["sel_index"] = idx
        state["_syncing"] = True
        type_var.set(it.get("type", "file"))
        name_var.set(it.get("name", ""))
        path_var.set(it.get("path", ""))
        opener_var.set(it.get("opener") or "(默认)")
        args_var.set(", ".join(it.get("args", [])))
        state["_syncing"] = False

    tree.bind("<<TreeviewSelect>>", on_tree_select)

    def _save_window_state():
        _s = load_ui_state()
        _s["window"] = {
            "width": root.winfo_width(),
            "height": root.winfo_height(),
            "x": root.winfo_x(),
            "y": root.winfo_y(),
        }
        _s["columns"] = {
            "type": tree.column("type", "width"),
            "name": tree.column("name", "width"),
            "path": tree.column("path", "width"),
            "opener": tree.column("opener", "width"),
        }
        _s["last_profile"] = state["profile"]
        save_ui_state(_s)

    def _on_close():
        _save_window_state()
        root.destroy()

    root.protocol("WM_DELETE_WINDOW", _on_close)

    ttk.Button(btns, text="添加",   command=add_new).pack(side="left")
    ttk.Button(btns, text="清空",   command=clear_form).pack(side="left", padx=4)
    ttk.Button(btns, text="删除选中", command=delete_selected).pack(side="left", padx=4)
    ttk.Button(btns, text="上移",   command=lambda: move(-1)).pack(side="left")
    ttk.Button(btns, text="下移",   command=lambda: move(1)).pack(side="left", padx=4)
    ttk.Button(btns, text="关闭",   command=lambda: _on_close()).pack(side="right", padx=4)

    if profiles:
        _last = _ui.get("last_profile")
        first = _last if _last in profiles else list(profiles.keys())[0]
        profile_var.set(first)
        load_profile(first)

    root.deiconify()
    root.mainloop()
def main():
    parser = argparse.ArgumentParser(description="日常启动器")
    parser.add_argument("--profile", "-p", default="work", help="配置档名（默认 work）")
    parser.add_argument("--list", "-l", action="store_true", help="只列出当前配置，不启动")
    parser.add_argument("--no-popup", action="store_true", help="不弹窗（静默模式）")
    parser.add_argument("--gui", action="store_true", help="打开图形化配置界面")
    parser.add_argument("--add", help="向当前 profile 追加一项，格式: type|name|path|opener")
    args = parser.parse_args()

    config = load_config()

    if args.gui:
        run_gui(config)
        return

    profiles = config.get("profiles", {})
    if args.profile not in profiles:
        print(f"配置档不存在: {args.profile}；可用: {', '.join(profiles)}")
        sys.exit(1)
    profile = profiles[args.profile]
    items = profile.setdefault("items", [])

    if args.add:
        parts = args.add.split("|")
        if len(parts) < 3:
            print("格式错误，应为: type|name|path|opener")
            sys.exit(1)
        item = {"type": parts[0], "name": parts[1], "path": parts[2]}
        if len(parts) > 3 and parts[3]:
            item["opener"] = parts[3]
        items.append(item)
        save_config(config)
        print(f"已添加到 [{args.profile}]: {item}")
        return

    if args.list:
        print(f"配置档 [{args.profile}] - {profile.get('name', '')}")
        for i, it in enumerate(items, 1):
            print(f"  {i}. [{it.get('type','file')}] {it.get('name') or it.get('path')}"
                  f"{'  (opener=' + it['opener'] + ')' if it.get('opener') else ''}")
        return

    log(f"=== 启动 [{args.profile}] {profile.get('name','')} ===")
    results = []
    for it in items:
        name, ok, err = launch_item(it, config)
        log(f"  [{'OK' if ok else 'FAIL: ' + err}] {name}")
        results.append((name, ok))

    ok_n = sum(1 for _, ok in results if ok)
    summary = f"完成：成功 {ok_n} / 共 {len(results)}"
    log(summary)

    if not args.no_popup:
        lines = [f"{'✅' if ok else '❌'} {name}" for name, ok in results]
        lines += ["", summary, f"日志: {LOG_FILE}"]
        show_popup(f"启动器 - {profile.get('name', args.profile)}", lines)


if __name__ == "__main__":
    main()
