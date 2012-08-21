'Dff script for Powerpoint (*.ppt)

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
    MsgBox "Usage: [CScript | WScript] diff-ppt.vbs base.ppt new.ppt", vbExclamation, "Invalid arguments"
    WScript.Quit 1
end if

Dim baseDocument, newDocument
baseDocument = arguments(0)
newDocument = arguments(1)

'check files existence
Call checkFileExistence(baseDocument)
Call checkFileExistence(newDocument)

On Error Resume Next
Dim application, source
Set application = WScript.CreateObject("Powerpoint.Application")
if Err.Number <> 0 then
   Wscript.echo "Powerpoint isn't installed."
   Wscript.Quit 1
end if
On Error Goto 0

application.visible = true

'Open base doc
Set source = application.Presentations.Open(baseDocument)
    
'Merge documents to show the changes
'This method or property is no longer supported by this version of PowerPoint. (Office 2007 Error)
source.Merge(newDocument)
    
'Mark the comparison presentation as saved to prevent the annoying
'"Save as" dialog from appearing.
application.ActivePresentation.Saved = 1
