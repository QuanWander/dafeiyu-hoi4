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
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
    [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] p, int cb);
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    public struct POINT { public int X; public int Y; }
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
    public static int[] ClientRect(IntPtr h) {
        RECT r; POINT p = new POINT();
        if (!GetClientRect(h, out r)) return null;
        if (!ClientToScreen(h, ref p)) return null;
        return new int[] { p.X, p.Y, r.Right - r.Left, r.Bottom - r.Top };
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

function Send-DfyPasteText([string]$text) {
    Initialize-DfyInput
    try { Set-Clipboard -Value $text -ErrorAction Stop } catch { [Windows.Forms.Clipboard]::SetText($text) }
    Start-Sleep -Milliseconds 80
    if ([DfyInput40]::Key(0x1D, 1) -ne 1) { throw 'Ctrl 按下失败。' }
    if ([DfyInput40]::Key(0x2F, 1) -ne 1) { throw 'V 按下失败。' }
    if ([DfyInput40]::Key(0x2F, 3) -ne 1) { throw 'V 抬起失败。' }
    if ([DfyInput40]::Key(0x1D, 3) -ne 1) { throw 'Ctrl 抬起失败。' }
    Start-Sleep -Milliseconds 180
}

function Get-DfyConsoleOpen {
    Initialize-DfyInput
    $h = Get-DfyHoi4Window
    if ($h -eq [IntPtr]::Zero) { return $false }
    if (-not [DfyInput40]::Focus($h)) { return $false }
    Add-Type -AssemblyName System.Drawing
    $cr = [DfyInput40]::ClientRect($h)
    if (-not $cr) { return $false }
    $w = $cr[2]
    $hgt = $cr[3]
    if ($w -lt 200 -or $hgt -lt 200) { return $false }
    $bmp = New-Object Drawing.Bitmap $w, $hgt
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($cr[0], $cr[1], 0, 0, $bmp.Size)
    $g.Dispose()
    $hits = 0
    $xEnd = [int]($w * 0.4)
    $yStart = [int]($hgt * 0.05)
    $yEnd = [int]($hgt * 0.65)
    for ($y = $yStart; $y -lt $yEnd; $y += 4) {
        for ($x = 0; $x -lt $xEnd; $x += 4) {
            $c = $bmp.GetPixel($x, $y)
            if ([math]::Abs($c.R - 39) -le 12 -and [math]::Abs($c.G - 36) -le 12 -and [math]::Abs($c.B - 33) -le 12 -and $c.R -ge $c.B) {
                $hits++
            }
        }
    }
    $bmp.Dispose()
    $script:DfyConsoleHits = $hits
    return ($hits -ge 1500)
}

function Invoke-DfyConsoleFile([string]$fileName) {
    if (-not (Test-DfyHoi4DebugMode)) { throw '游戏没有用 -debug_mode 启动，控制台不可用。' }
    $h = Get-DfyHoi4Window
    if ($h -eq [IntPtr]::Zero) { throw '没有找到 HOI4 窗口。' }
    if (-not [DfyInput40]::Focus($h)) { throw '无法把 HOI4 切到前台，拒绝输入。' }
    $wasOpen = [bool](Get-DfyConsoleOpen)
    if (-not $wasOpen) {
        Send-DfyScanKey 0x29
        Start-Sleep -Milliseconds 800
        if (-not (Get-DfyConsoleOpen)) { throw '控制台没有打开，拒绝输入。' }
    }
    Send-DfyPasteText "run $fileName"
    Start-Sleep -Milliseconds 120
    Send-DfyScanKey 0x1C
    Start-Sleep -Milliseconds 700
    # Always return to a known closed state.
    if (Get-DfyConsoleOpen) {
        Send-DfyScanKey 0x29
        Start-Sleep -Milliseconds 800
        if (Get-DfyConsoleOpen) {
            Send-DfyScanKey 0x29
            Start-Sleep -Milliseconds 600
        }
        if (Get-DfyConsoleOpen) { throw '命令已输入，但控制台未关闭；请手动按 ~ 关闭。' }
    }
}
