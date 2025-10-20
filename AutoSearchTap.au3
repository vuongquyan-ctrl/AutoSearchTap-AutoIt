#include <GDIPlus.au3>

; ===========================================
; 🧠 AUTOSEARCHTAP v4
; Tìm ảnh nhỏ (pattern) trong vùng ảnh lớn.
; Trả về [x, y] nếu tìm thấy, @error nếu không.
; Bạn tự quyết định hành động tiếp theo.
; ===========================================

Global Const $g_sADB = "D:\LDPlayer\LDPlayer9\adb.exe"
Global Const $g_sDevice = "emulator-5556" ; Xem bằng "adb devices"

; ======== KHỞI TẠO / GIẢI PHÓNG GDI+ ========
Func _GDIInit()
    _GDIPlus_Startup()
EndFunc

Func _GDIEnd()
    _GDIPlus_Shutdown()
EndFunc


; ======== HÀM DÒ HÌNH (trả về mảng [x,y]) ==========
Func _SearchPatternRegion($sImagePath, $sPatternPath, _
                          $xStart, $yStart, $xEnd, $yEnd, _
                          $tolerance = 3000)

    Local $hImage = _GDIPlus_ImageLoadFromFile($sImagePath)
    If @error Then Return SetError(1, 0, "❌ Không mở được ảnh gốc")

    Local $hPattern = _GDIPlus_ImageLoadFromFile($sPatternPath)
    If @error Then
        _GDIPlus_ImageDispose($hImage)
        Return SetError(2, 0, "❌ Không mở được pattern")
    EndIf

    Local $pW = _GDIPlus_ImageGetWidth($hPattern)
    Local $pH = _GDIPlus_ImageGetHeight($hPattern)
    Local $bestDiff = 99999999, $bestX = -1, $bestY = -1

    ; Giới hạn vùng
    Local $iW = _GDIPlus_ImageGetWidth($hImage)
    Local $iH = _GDIPlus_ImageGetHeight($hImage)
    If $xStart < 0 Then $xStart = 0
    If $yStart < 0 Then $yStart = 0
    If $xEnd > $iW - 1 Then $xEnd = $iW - 1
    If $yEnd > $iH - 1 Then $yEnd = $iH - 1

    ; 5 điểm: trung tâm + 4 góc
    Local $aCheck[5][2] = [[1,1],[0,0],[2,0],[0,2],[2,2]]

    For $x = $xStart To ($xEnd - $pW + 1)
        For $y = $yStart To ($yEnd - $pH + 1)
            Local $sum = 0
            For $i = 0 To 4
                Local $ix = $aCheck[$i][0]
                Local $iy = $aCheck[$i][1]
                Local $c1 = BitAND(_GDIPlus_BitmapGetPixel($hImage, $x + $ix, $y + $iy), 0xFFFFFF)
                Local $c2 = BitAND(_GDIPlus_BitmapGetPixel($hPattern, $ix, $iy), 0xFFFFFF)
                $sum += Abs($c1 - $c2)
                If $sum > $tolerance Then ExitLoop
            Next
            If $sum < $bestDiff Then
                $bestDiff = $sum
                $bestX = $x
                $bestY = $y
            EndIf
        Next
    Next

    _GDIPlus_ImageDispose($hImage)
    _GDIPlus_ImageDispose($hPattern)

    If $bestDiff > $tolerance Then
        Return SetError(3, 0, 0)
    EndIf

    Local $aResult[2] = [$bestX, $bestY]
    Return $aResult
EndFunc


; ======== TAP QUA ADB ==========
Func _SendTap($x, $y)
    Local $sCmd = '"' & $g_sADB & '" -s ' & $g_sDevice & ' shell input tap ' & $x & ' ' & $y
    ConsoleWrite("➡️ " & $sCmd & @CRLF)
    RunWait(@ComSpec & " /c " & $sCmd, "", @SW_HIDE)
    ConsoleWrite("✅ Tap (" & $x & "," & $y & ") tới " & $g_sDevice & @CRLF)
EndFunc
