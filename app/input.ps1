# DaFeiYu HOI4 software console driver.
# Requires the game to run with -debug_mode and a foreground-switchable window.
# This is the corrected x64 INPUT structure (40 bytes), not the broken 32-byte variant.

$script:DfyInputReady = $false

function Initialize-DfyInput {
    if ($script:DfyInputReady) { return }
    if (-not ('DfyInput40' -as [type])) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class DfyInput40 {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
    [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] p, int cb);
    public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; public UIntPtr dwExtraInfo; }
    public struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public UIntPtr dwExtraInfo; }
    [StructLayout(LayoutKind.Explicit)] public struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    public struct INPUT { public uint type; public INPUTUNION u; }
    public static IntPtr Find(string t) {
        IntPtr f = IntPtr.Zero;
        EnumWindows((h, l) => { var b = new StringBuilder(256); GetWindowText(h, b, 256); if (b.ToString() == t) { f = h; return false; } return true; }, IntPtr.Zero);
        return f;
    }
    public static bool Focus(IntPtr h) {
        for (int i = 0; i < 4; i++) {
            if (GetForegroundWindow() == h) return true;
            uint fg = GetWindowThreadProcessId(GetForegroundWindow(), IntPtr.Zero);
            uint me = GetCurrentThreadId();
            bool att = fg != 0 && fg != me && AttachThreadInput(me, fg, true);
            try {
                if (i > 0) { keybd_event(0x12, 0, 0, UIntPtr.Zero); keybd_event(0x12, 0, 2, UIntPtr.Zero); }
                BringWindowToTop(h); SetForegroundWindow(h); SetFocus(h);
            } finally { if (att) AttachThreadInput(me, fg, false); }
            System.Threading.Thread.Sleep(220);
        }
        return GetForegroundWindow() == h;
    }
    public static uint Key(ushort scan, uint flags) {
        var a = new INPUT[1]; a[0].type = 1; a[0].u.ki.wScan = scan; a[0].u.ki.dwFlags = flags;
        return SendInput(1, a, Marshal.SizeOf(typeof(INPUT)));
    }
    public static uint Char(char c) {
        var a = new INPUT[1]; a[0].type = 1; a[0].u.ki.wScan = c; a[0].u.ki.dwFlags = 4;
        var b = new INPUT[1]; b[0].type = 1; b[0].u.ki.wScan = c; b[0].u.ki.dwFlags = 6;
        var arr = new INPUT[2] { a[0], b[0] };
        return SendInput(2, arr, Marshal.SizeOf(typeof(INPUT)));
    }
}
"@
    }
    $script:DfyInputReady = $true
}

function Get-DfyHoi4Window {
    Initialize-DfyInput
    $p = Get-Process hoi4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) { return [IntPtr]::Zero }
    $h = [DfyInput40]::Find([string]$p.MainWindowTitle)
    if ($h -eq [IntPtr]::Zero -and $p.MainWindowHandle -ne 0) { $h = [IntPtr]$p.MainWindowHandle }
    return $h
}

function Test-DfyHoi4DebugMode {
    $p = Get-Process hoi4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) { return $false }
    try {
        $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction Stop).CommandLine
        return [bool]($cmd -match '(^|\s)-debug_mode(\s|$)')
    } catch { return $false }
}

function Send-DfyText([string]$text) {
    Initialize-DfyInput
    foreach ($ch in $text.ToCharArray()) {
        if ([DfyInput40]::Char($ch) -lt 2) { throw 'SendInput 输入文本失败。' }
        Start-Sleep -Milliseconds 30
    }
}

function Send-DfyScanKey([int]$scan) {
    Initialize-DfyInput
    if ([DfyInput40]::Key([int]$scan, 1) -ne 1) { throw 'SendInput 按键按下失败。' }
    if ([DfyInput40]::Key([int]$scan, 3) -ne 1) { throw 'SendInput 按键抬起失败。' }
}

function Invoke-DfyConsoleFile([string]$fileName) {
    if (-not (Test-DfyHoi4DebugMode)) { throw '游戏没有用 -debug_mode 启动，控制台不可用。' }
    $h = Get-DfyHoi4Window
    if ($h -eq [IntPtr]::Zero) { throw '没有找到 HOI4 窗口。' }
    if (-not [DfyInput40]::Focus($h)) { throw '无法把 HOI4 切到前台，拒绝输入。' }
    # Assume the console is closed. Opening/closing is a toggle; callers should not leave it open.
    Send-DfyScanKey 0x29       # `
    Start-Sleep -Milliseconds 350
    Send-DfyText "run $fileName"
    Start-Sleep -Milliseconds 120
    Send-DfyScanKey 0x1C       # Enter
    Start-Sleep -Milliseconds 700
    Send-DfyScanKey 0x29       # close console
}
