#include "AutoSearchTap.au3"

; ============================================================
; 🎯 Example.au3 - Demo for AutoSearchTap
; Shows how to detect a small pattern inside a region of an image,
; then tap or notify when it’s found.
;
; AutoSearchTap.au3 (GDI+ Pixel Matching for AutoIt)
; Developed collaboratively by An Vuong & GPT-5
; Powered by OpenAI GPT-5 with pixel-level pattern recognition logic.
; ============================================================

; --- SETTINGS ------------------------------------------------
Global Const $sImagePath  = @ScriptDir & "\PICDATA\LDPlayer-1.png" ; Source image
Global Const $sPatternPath = @ScriptDir & "\Pattern.png"            ; Target pattern image
Global Const $g_sADB = "D:\LDPlayer\LDPlayer9\adb.exe"              ; ADB executable path
Global Const $g_sDevice = "emulator-5556"                           ; LDPlayer device ID (check using "adb devices")


; --- INIT ----------------------------------------------------
ConsoleWrite("🚀 Starting AutoSearchTap Demo..." & @CRLF)
_GDIInit()

; --- SEARCH REGION -------------------------------------------
; Ví dụ: dò trong vùng [372,464 - 432,519]
Local $xStart = 372, $yStart = 464, $xEnd = 432, $yEnd = 519
Local $tolerance = 3000

; --- DETECT ---------------------------------------------------
Local $res = _SearchPatternRegion($sImagePath, $sPatternPath, $xStart, $yStart, $xEnd, $yEnd, $tolerance)

If IsArray($res) Then
    ConsoleWrite("✅ Pattern detected at X=" & $res[0] & ", Y=" & $res[1] & @CRLF)

    ; === OPTION 1: Tap on the detected spot (center of 3x3)
    _SendTap($res[0] + 1, $res[1] + 1)

    ; === OPTION 2: Instead of tap, you can show a message:
    ; MsgBox(64, "Pattern Found", "Found at: " & $res[0] & "," & $res[1])

    ; === OPTION 3: Or perform your own custom logic
    ; _DoSomethingElse($res[0], $res[1])

Else
    ConsoleWrite("❌ Pattern not found in this region." & @CRLF)
    MsgBox(48, "Result", "Pattern not found in region: [372,464 - 432,519]")
EndIf

; --- CLEANUP -------------------------------------------------
_GDIEnd()
ConsoleWrite("✅ Demo complete." & @CRLF)
