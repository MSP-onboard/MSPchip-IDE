'Dff script for Open Office Text files (*.odt) and Open Office Calc files(*.ods)

'Option Explicit

'---- Start functions

Sub checkFileExistence(filePath)
    Dim fileObject
    Set fileObject = CreateObject("Scripting.FileSystemObject")
    if fileObject.FileExists(filePath) = false then
        MsgBox "File: " + filePath + " does not exist.  Failed to compare the documents.", vbExclamation, "File not found"
        Wscript.Quit 1
    end if   
    Set fileObject = Nothing
end Sub


'Converts a Ms Windows local pathname in URL (RFC 1738)
'TODO : UNC pathnames, more character conversions
public function ConvertToUrl(strFile)
    strFile = Replace(strFile, "\", "/")
    strFile = Replace(strFile, ":", "|")
    strFile = Replace(strFile, "%", "%25")
    strFile = Replace(strFile, " ", "%20")    
    strFile = "file:///" + strFile
        
    ConvertToUrl = uriTranslator.translateToInternal(strFile)        
end function


'Creates a sequence of com.sun.star.beans.PropertyValue s
public function MakePropertyValue(cName, uValue)
    Dim oStruct
    Set oStruct = serviceManager.Bridge_GetStruct("com.sun.star.beans.PropertyValue")
    oStruct.Name = cName
    oStruct.Value = uValue
    Set MakePropertyValue = oStruct    
end function 

'---- End functions


'check if Open Office is installed
Dim serviceManager, desktop, uriTranslator, dispatcher

On Error Resume Next
Set serviceManager= CreateObject("com.sun.star.ServiceManager")
if Err.Number <> 0 then
   MsgBox "OpenOffice isn't installed.", vbExclamation, "OpenOffice problem"
   Wscript.Quit 1
end if
On Error Goto 0

Set desktop = serviceManager.createInstance("com.sun.star.frame.Desktop")
Set uriTranslator = serviceManager.createInstance("com.sun.star.uri.ExternalUriReferenceTranslator")
Set dispatcher = serviceManager.CreateInstance("com.sun.star.frame.DispatchHelper")

'check arguments
Dim arguments
Set arguments = WScript.Arguments
if arguments.Count < 2 then
    MsgBox "Usage: [CScript | WScript] diff-odX.vbs base-file new-file", vbExclamation, "Invalid arguments"
    WScript.Quit 1
end if

Dim baseDocument, newDocument
baseDocument = arguments(0)
newDocument = arguments(1)

'check files existence
Call checkFileExistence(baseDocument)
Call checkFileExistence(newDocument)

'TODO ? set readonly flag 

'prepare uris
baseDocument = ConvertToUrl(baseDocument)
newDocument = ConvertToUrl(newDocument)

'open new doc
Dim propertyValue(0), objDocument
Set propertyValue(0) = MakePropertyValue("ShowTrackedChanges", true)
Set objDocument = desktop.loadComponentFromURL(newDocument, "_blank", 0, propertyValue)

'run compare
Dim frame
Set frame = desktop.getCurrentFrame
dispatcher.executeDispatch frame, ".uno:ShowTrackedChanges", "", 0, propertyValue
propertyValue(0).Name = "URL"
propertyValue(0).Value = baseDocument
dispatcher.executeDispatch frame, ".uno:CompareDocuments", "", 0, propertyValue
