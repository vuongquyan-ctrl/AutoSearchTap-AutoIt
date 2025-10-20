#include <GDIPlus.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <EditConstants.au3>
#include <ButtonConstants.au3>

Opt("GUIOnEventMode", 1)

; ==== CONFIGURATION ====
Global Const $sImagePath = @ScriptDir & "\PICDATA\LDPlayer-1.png"
Global Const $sPatternFile = @ScriptDir & "\Pattern.png"

_GDIPlus_Startup()
Global $hImage = _GDIPlus_ImageLoadFromFile($sImagePath)
If @error Or $hImage = 0 Then
    MsgBox(16, "Error", "Cannot open image: " & $sImagePath)
    _GDIPlus_Shutdown()
    Exit
EndIf

; ==== IMAGE SIZE ====
Global $iW = _GDIPlus_ImageGetWidth($hImage)
Global $iH = _GDIPlus_ImageGetHeight($hImage)
Global $dispW = 960, $dispH = 540
Global $scaleW = $dispW / $iW, $scaleH = $dispH / $iH

; ==== VARIABLES ====
Global $gX = Int($iW / 2), $gY = Int($iH / 2)
Global $bSelecting = False, $bDragging = False
Global $aSel[4] = [0, 0, 0, 0]

; ==== MAIN GUI ====
Global $hGUI = GUICreate("PatternMaker3x3", 1200, 600)
Global $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hGUI)

; === Main image display ===
Global $hPicArea = GUICtrlCreateLabel("", 0, 0, $dispW, $dispH)
GUICtrlSetBkColor(-1, 0x000000)

; === Sidebar tools ===
GUICtrlCreateLabel("Zoom ×8", 980, 10, 200, 20)
Global $ZoomBox = GUICtrlCreatePic("", 980, 40, 200, 200)

GUICtrlCreateLabel("Coordinate [x,y]:", 980, 260, 200, 20)
Global $CoordInput = GUICtrlCreateInput("", 980, 280, 200, 24, $ES_CENTER)
GUICtrlSetBkColor(-1, 0xFFFFFF)
GUICtrlSetTip($CoordInput, "Press Ctrl+C to copy pixel coordinates")

Global $btnSave = GUICtrlCreateButton("💾 Save 3×3 Pattern", 980, 315, 200, 35)
GUICtrlSetOnEvent($btnSave, "_BtnSavePattern")

GUICtrlCreateLabel("📐 Selection (Shift + Drag):", 980, 365, 200, 20)
Global $lblInfo = GUICtrlCreateLabel("", 980, 390, 200, 50)

GUICtrlCreateLabel("Copy region (x1,y1,x2,y2):", 980, 450, 200, 20)
Global $CopyInput = GUICtrlCreateInput("", 980, 470, 200, 24, $ES_CENTER)
GUICtrlSetBkColor(-1, 0xFFFFFF)
GUICtrlSetTip($CopyInput, "Ctrl+C to copy large region coordinates")

GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
GUISetState(@SW_SHOW)
_UpdateDisplay()

AdlibRegister("_HandleKeys", 25)

; ==== MAIN LOOP ====
While 1
    Local $stateShift = _WinAPI_GetAsyncKeyState(0x10)
    Local $stateLMB = _WinAPI_GetAsyncKeyState(0x01)
    Local $aPos = MouseGetPos(), $aWin = WinGetPos($hGUI)
    Local $x = $aPos[0] - $aWin[0]
    Local $y = $aPos[1] - $aWin[1] - 40

    ; Limit inside image area
    If $x >= 0 And $x < $dispW And $y >= 0 And $y < $dispH Then
        ; SHIFT + DRAG = region selection
        If $stateShift And $stateLMB Then
            If Not $bDragging Then
                $bDragging = True
                $aSel[0] = $x
                $aSel[1] = $y
            EndIf
            $aSel[2] = $x
            $aSel[3] = $y
            _UpdateDisplay()
            _DrawRect($aSel[0], $aSel[1], $x - $aSel[0], $y - $aSel[1], 0xFFFFFF00)
        ElseIf $bDragging And Not $stateLMB Then
            $bDragging = False
            _FinalizeSelection()
        EndIf

        ; CLICK = pick pixel
        If Not $stateShift And $stateLMB Then
            $gX = Int($x / $scaleW)
            $gY = Int($y / $scaleH)
            $bSelecting = True
            _UpdateDisplay()
            _DrawCross($gX, $gY)
            _ShowPreview($gX, $gY)
            GUICtrlSetData($CoordInput, "[" & $gX & "," & $gY & "]")
            Sleep(200)
        EndIf
    EndIf
    Sleep(15)
WEnd

; ==== DISPLAY IMAGE ====
Func _UpdateDisplay()
    Local $bgColor = _WinAPI_GetSysColor($COLOR_BTNFACE)
    Local $argb = BitOR(0xFF000000, BitAND($bgColor, 0x00FFFFFF))
    _GDIPlus_GraphicsClear($hGraphics, $argb)
    _GDIPlus_GraphicsDrawImageRect($hGraphics, $hImage, 0, 0, $dispW, $dispH)
EndFunc

; ==== DRAW RECT ====
Func _DrawRect($x, $y, $w, $h, $color)
    Local $pen = _GDIPlus_PenCreate(BitOR(0xFF000000, $color), 2)
    _GDIPlus_GraphicsDrawRect($hGraphics, $x, $y, $w, $h, $pen)
    _GDIPlus_PenDispose($pen)
EndFunc

; ==== DRAW 3×3 CROSS ====
Func _DrawCross($x, $y)
    Local $px = $x * $scaleW, $py = $y * $scaleH
    Local $pen = _GDIPlus_PenCreate(0xFFFF0000, 1)
    _GDIPlus_GraphicsDrawRect($hGraphics, $px - 2, $py - 2, 4, 4, $pen)
    _GDIPlus_PenDispose($pen)
EndFunc

; ==== SHOW 8× ZOOM PREVIEW ====
Func _ShowPreview($x, $y)
    Local $crop = _GDIPlus_BitmapCloneArea($hImage, $x - 1, $y - 1, 3, 3, $GDIP_PXF32ARGB)
    Local $zoom = _GDIPlus_BitmapCreateFromScan0(200, 200)
    Local $gfx = _GDIPlus_ImageGetGraphicsContext($zoom)
    _GDIPlus_GraphicsSetInterpolationMode($gfx, $GDIP_INTERPOLATIONMODE_NEARESTNEIGHBOR)
    _GDIPlus_GraphicsDrawImageRect($gfx, $crop, 0, 0, 200, 200)
    Local $sTemp = @TempDir & "\preview.bmp"
    _GDIPlus_ImageSaveToFile($zoom, $sTemp)
    GUICtrlSetImage($ZoomBox, $sTemp)
    _GDIPlus_GraphicsDispose($gfx)
    _GDIPlus_ImageDispose($zoom)
    _GDIPlus_ImageDispose($crop)
EndFunc

; ==== HANDLE KEYS ====
Func _HandleKeys()
    If _WinAPI_GetAsyncKeyState(0x1B) Then _Exit() ; ESC = exit

    If Not $bSelecting Then Return
    Local $moved = False

    If _WinAPI_GetAsyncKeyState(0x26) Then $gY -= 1 ; ↑
    If _WinAPI_GetAsyncKeyState(0x28) Then $gY += 1 ; ↓
    If _WinAPI_GetAsyncKeyState(0x25) Then $gX -= 1 ; ←
    If _WinAPI_GetAsyncKeyState(0x27) Then $gX += 1 ; →
    If _WinAPI_GetAsyncKeyState(0x26) Or _WinAPI_GetAsyncKeyState(0x28) Or _
       _WinAPI_GetAsyncKeyState(0x25) Or _WinAPI_GetAsyncKeyState(0x27) Then $moved = True

    If $gX < 1 Then $gX = 1
    If $gY < 1 Then $gY = 1
    If $gX > $iW - 2 Then $gX = $iW - 2
    If $gY > $iH - 2 Then $gY = $iH - 2

    If $moved Then
        _UpdateDisplay()
        _DrawCross($gX, $gY)
        _ShowPreview($gX, $gY)
        GUICtrlSetData($CoordInput, "[" & $gX & "," & $gY & "]")
    EndIf
EndFunc

; ==== SAVE BUTTON ====
Func _BtnSavePattern()
    If Not $bSelecting Then Return
    _SavePattern($gX, $gY)
    ToolTip("✅ Pattern.png saved [" & $gX & "," & $gY & "]", 980, 430)
    Sleep(600)
    ToolTip("")
EndFunc

; ==== SAVE 3×3 IMAGE ====
Func _SavePattern($x, $y)
    Local $hCrop = _GDIPlus_BitmapCloneArea($hImage, $x - 1, $y - 1, 3, 3, $GDIP_PXF32ARGB)
    _GDIPlus_ImageSaveToFile($hCrop, $sPatternFile)
    _GDIPlus_ImageDispose($hCrop)
EndFunc

; ==== FINALIZE REGION SELECTION ====
Func _FinalizeSelection()
    Local $x1 = Int(_Min($aSel[0], $aSel[2]) / $scaleW)
    Local $y1 = Int(_Min($aSel[1], $aSel[3]) / $scaleH)
    Local $x2 = Int(_Max($aSel[0], $aSel[2]) / $scaleW)
    Local $y2 = Int(_Max($aSel[1], $aSel[3]) / $scaleH)
    Local $w = $x2 - $x1, $h = $y2 - $y1

    Local $info = StringFormat("%d, %d, %d, %d", $x1, $y1, $x2, $y2)
    GUICtrlSetData($lblInfo, "(" & $w & "×" & $h & ")")
    GUICtrlSetData($CopyInput, $info)
    ClipPut($info)
    ToolTip("📋 Copied: " & $info, 980, 500)
    Sleep(800)
    ToolTip("")
EndFunc

; ==== HELPERS ====
Func _Min($a, $b)
    Return ($a < $b) ? $a : $b
EndFunc
Func _Max($a, $b)
    Return ($a > $b) ? $a : $b
EndFunc

; ==== EXIT ====
Func _Exit()
    _GDIPlus_GraphicsDispose($hGraphics)
    _GDIPlus_ImageDispose($hImage)
    _GDIPlus_Shutdown()
    Exit
EndFunc
