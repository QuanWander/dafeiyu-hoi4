# DaFeiYu HOI4 HID bridge: serial control for a real USB HID keyboard board.
# No keyboard simulation, no driver, no DLL injection.

function Get-DfyHidPorts {
    $rows = @()
    try {
        $rows = @(Get-CimInstance Win32_SerialPort -ErrorAction SilentlyContinue | ForEach-Object {
            [pscustomobject]@{ DeviceID = [string]$_.DeviceID; Name = [string]$_.Name; Description = [string]$_.Description }
        })
    } catch {}
    return $rows
}

function Find-DfyHidPort {
    if ($script:cfg -and $script:cfg.hid_port) {
        $configured = [string]$script:cfg.hid_port
        if ($configured) { return $configured }
    }
    $ports = @(Get-DfyHidPorts)
    foreach ($p in $ports) {
        $text = "$($p.Name) $($p.Description)"
        if ($text -match '蓝牙|Bluetooth') { continue }
        if ($text -match 'Pico|Arduino|Leonardo|Pro Micro|USB Serial|CH340|CP210|USB 串行|USB-SERIAL') {
            return $p.DeviceID
        }
    }
    return ''
}

function Send-DfyHidCommand([string]$port, [string]$command, [int]$timeoutMs = 2500) {
    if (-not $port) { throw '没有配置 HID 串口。' }
    $sp = New-Object System.IO.Ports.SerialPort
    try {
        $sp.PortName = $port
        $sp.BaudRate = 115200
        $sp.Parity = [System.IO.Ports.Parity]::None
        $sp.DataBits = 8
        $sp.StopBits = [System.IO.Ports.StopBits]::One
        $sp.Handshake = [System.IO.Ports.Handshake]::None
        $sp.ReadTimeout = $timeoutMs
        $sp.WriteTimeout = $timeoutMs
        $sp.DtrEnable = $true
        $sp.Open()
        Start-Sleep -Milliseconds 150
        $sp.WriteLine($command)
        $deadline = (Get-Date).AddMilliseconds($timeoutMs)
        while ((Get-Date) -lt $deadline) {
            try {
                $line = $sp.ReadLine().Trim()
                if ($line) { return $line }
            } catch { Start-Sleep -Milliseconds 100 }
        }
        return ''
    } finally {
        try { if ($sp.IsOpen) { $sp.Close() } } catch {}
        $sp.Dispose()
    }
}

function Invoke-DfyHidRun {
    $port = Find-DfyHidPort
    if (-not $port) { throw '没有找到 HID 板；插上 Pico/Leonardo 或配置 hid_port。' }
    $reply = Send-DfyHidCommand $port 'RUN' 4000
    if ($reply -ne 'OK') { throw "HID 返回：$reply" }
    return $port
}
