
---

## 🧩 PatternMaker3x3 — Helper Tool

This GUI tool lets you **visually select and save a 3×3 pattern** directly from your screenshot.

### 🎨 Features
- Click anywhere on the image to pick the center pixel.
- Use arrow keys ↑↓←→ to fine-tune position.
- Press 💾 “Save 3×3 Pattern” to export `Pattern.png`.
- Hold **Shift + Drag** to get coordinates of a region (copied to clipboard automatically).

### 🧰 Usage
1. Place your base image inside `PICDATA\LDPlayer-1.png`
2. Run `PatternMaker3x3.au3`
3. Adjust and save `Pattern.png`
4. Use it with `AutoSearchTap.au3` for precise pattern detection.

---

# 🎯 AutoSearchTap.au3  
### GDI+ Pixel Matching Engine for AutoIt  

AutoSearchTap is a **pure AutoIt GDI+ engine** for pixel-based image detection.  
It can detect small patterns (3×3, 5×5, etc.) inside screenshots and perform custom actions —  
such as **tapping via ADB**, **triggering functions**, or **showing messages**.

Designed for **LDPlayer / Android automation**,  
but can also be used for any pixel-based image matching project in AutoIt.

---

## 🚀 Features

- ⚡ **Fast pixel-based matching** using 5-point sampling (center + 4 corners)
- 🎯 **Accurate detection** with configurable color tolerance
- 🧩 **Pure AutoIt GDI+** (no ImageSearch.dll or external dependencies)
- 🔧 **Customizable actions:** tap, message, or return coordinates
- 📱 **ADB integration** for direct tap commands to LDPlayer / Android emulators
- 🧠 **Developer-friendly API** with `If IsArray($res) Then ...` logic

---

## 🧠 Example Usage

```autoit
#include "AutoSearchTap.au3"

_GDIInit()

Local $res = _SearchPatternRegion(@ScriptDir & "\PICDATA\LDPlayer-1.png", _
                                  @ScriptDir & "\Pattern.png", _
                                  372, 464, 432, 519, 3000)

If IsArray($res) Then
    ConsoleWrite("✅ Found pattern at: " & $res[0] & "," & $res[1] & @CRLF)
    _SendTap($res[0]+1, $res[1]+1) ; tap at center
Else
    ConsoleWrite("❌ Pattern not found." & @CRLF)
EndIf

_GDIEnd()
