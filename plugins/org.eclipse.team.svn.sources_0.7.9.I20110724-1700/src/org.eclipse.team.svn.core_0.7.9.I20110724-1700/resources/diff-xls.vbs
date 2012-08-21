'Dff script for Excel (*.xls, *.xlsx)

'Option Explicit

Sub checkFileExistence(filePath)
    Dim fileObject
    Set fileObject = CreateObject("Scripting.FileSystemObject")
    if fileObject.FileExists(filePath) = false then
        MsgBox "File: " + filePath + " does not exist.  Failed to compare the documents.", vbExclamation, "File not found"
        Wscript.Quit 1
    end if   
    Set fileObject = Nothing
end Sub

'check arguments
Dim arguments
Set arguments = WScript.Arguments
if arguments.Count < 2 then
    MsgBox "Usage: [CScript | WScript] diff-xls.vbs base new", vbExclamation, "Invalid arguments"
    WScript.Quit 1
end if

Dim baseDocument, newDocument
baseDocument = arguments(0)
newDocument = arguments(1)

'check files existence
Call checkFileExistence(baseDocument)
Call checkFileExistence(newDocument)

On Error Resume Next
Set application = Wscript.CreateObject("Excel.Application")
if Err.Number <> 0 then
   Wscript.Echo "Excel isn't installed."
   Wscript.Quit 1
end if
On Error Goto 0

'Open sheets
Call application.Workbooks.Open(baseDocument)
Call application.Workbooks.Open(newDocument)
application.Visible = True

'Create a compare side by side view
application.Windows.CompareSideBySideWith(application.Windows(2).Caption)
If Err.Number <> 0 Then
	application.Application.WindowState = xlMaximized
	application.Windows.Arrange(-4128)
End If

'Mark differences in newDocument red
i = 1
For Each sheet In application.Workbooks(2).Worksheets
	sheet.Cells.FormatConditions.Delete
	application.Workbooks(1).Sheets(i).Copy ,application.Workbooks(2).Sheets(application.Workbooks(2).Sheets.Count)
	application.Workbooks(2).Sheets(application.Workbooks(2).Sheets.Count).Name = "Dummy_for_Comparison" & i
	sheet.Activate
	original_content = sheet.Cells(1,1).Formula
	String sFormula	
	sheet.Cells(1,1).Formula = "=INDIRECT(""Dummy_for_Comparison" & i & "!""&ADDRESS(ROW(),COLUMN()))" 
	sFormula = sheet.Cells(1,1).FormulaLocal
	sheet.Cells(1,1).Formula = original_content
	const xlCellValue = 1
	const xlNotEqual = 4
	sheet.Cells.FormatConditions.Add xlCellValue, xlNotEqual, sFormula
	sheet.Cells.FormatConditions(1).Interior.ColorIndex = 3
	i = i + 1 
next
