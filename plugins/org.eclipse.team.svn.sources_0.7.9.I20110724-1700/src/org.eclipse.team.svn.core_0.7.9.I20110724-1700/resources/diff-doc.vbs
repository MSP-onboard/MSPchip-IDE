'Dff script for Word (*.doc, *.docx)

'Option Explicit

'---- Constants
Dim Office_2000, Office_2002, Office_2003, Office_2007
Office_2000 = 9
Office_2002 = 10
Office_2003 = 11
Office_2007 = 12

Dim wdCompareTargetNew, wdMasterView, wdNormalView, wdOutlineView, wdDoNotSaveChanges
wdCompareTargetNew = 2
'WdViewType
wdMasterView = 5
wdNormalView = 1
wdOutlineView = 2
'WdSaveOptions
wdDoNotSaveChanges = 0

Sub runWithOpenOffice(baseDocument, newDocument)
    Dim serviceManager, desktop, uriTranslator, dispatcher
	On Error Resume Next	
	Set serviceManager= CreateObject("com.sun.star.ServiceManager")	
	Call CheckError("OpenOffice isn't installed.")	
	On Error Goto 0
	
	Set desktop = serviceManager.createInstance("com.sun.star.frame.Desktop")
	Set uriTranslator = serviceManager.createInstance("com.sun.star.uri.ExternalUriReferenceTranslator")
	Set dispatcher = serviceManager.CreateInstance("com.sun.star.frame.DispatchHelper")	
	
	'prepare uris
	baseDocument = ConvertToUrl(baseDocument, uriTranslator)
	newDocument = ConvertToUrl(newDocument, uriTranslator)
	
	'open new doc
	Dim propertyValue(0), objDocument
	Set propertyValue(0) = MakePropertyValue("ShowTrackedChanges", true, serviceManager)
	Set objDocument = desktop.loadComponentFromURL(newDocument, "_blank", 0, propertyValue)		
	
	'run compare
	Dim frame
	Set frame = desktop.getCurrentFrame
	dispatcher.executeDispatch frame, ".uno:ShowTrackedChanges", "", 0, propertyValue
	propertyValue(0).Name = "URL"
	propertyValue(0).Value = baseDocument
	dispatcher.executeDispatch frame, ".uno:CompareDocuments", "", 0, propertyValue
end Sub

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

Sub CheckError(message)
	if Err.Number <> 0 then
		WScript.Echo(message)
		WScript.Quit(1)
	end if	
End Sub

'Converts a Ms Windows local pathname in URL (RFC 1738)
'TODO : UNC pathnames, more character conversions
public function ConvertToUrl(strFile, uriTranslator)
    strFile = Replace(strFile, "\", "/")
    strFile = Replace(strFile, ":", "|")
    strFile = Replace(strFile, "%", "%25")
    strFile = Replace(strFile, " ", "%20")    
    strFile = "file:///" + strFile
        
    ConvertToUrl = uriTranslator.translateToInternal(strFile)        
end function

'Creates a sequence of com.sun.star.beans.PropertyValue s
public function MakePropertyValue(cName, uValue, serviceManager)
    Dim oStruct
    Set oStruct = serviceManager.Bridge_GetStruct("com.sun.star.beans.PropertyValue")
    oStruct.Name = cName
    oStruct.Value = uValue
    Set MakePropertyValue = oStruct    
end function 

'---- End functions


'check arguments
Dim arguments
Set arguments = WScript.Arguments
if arguments.Count < 2 then
    MsgBox "Usage: [CScript | WScript] diff-doc.vbs base-file new-file", vbExclamation, "Invalid arguments"
    WScript.Quit 1
end if

Dim baseDocument, newDocument
baseDocument = arguments(0)
newDocument = arguments(1)

'check files existence
Call checkFileExistence(baseDocument)
Call checkFileExistence(newDocument)

'run word
On Error Resume Next
Dim application
Set application = WScript.CreateObject("Word.Application")
if Err.Number <> 0 then
	Err.Clear()
	On Error Goto 0	
	Call runWithOpenOffice(baseDocument, newDocument)
	WScript.Quit 0
end if
On Error Goto 0

application.visible = true
Dim version
version = application.Version

if version >= Office_2007 then
	Dim tempDoc
	tempDoc = newDocument
	newDocument = baseDocument
	baseDocument = tempDoc
end if

'Open document
On Error Resume Next
Dim document
Set document = application.Documents.Open(newDocument, true, true)
Call CheckError("Failed to open: " + newDocument)
On Error Goto 0

'check if the current document outline
if (((document.ActiveWindow.View.Type = wdOutlineView) OR (document.ActiveWindow.View.Type = wdMasterView)) AND (document.Subdocuments.Count = 0)) then
    document.ActiveWindow.View.Type = wdNormalView
end if

'Compare for Office 2000 and earlier
if version <= Office_2000 then
	On Error Resume Next
    document.Compare(baseDocument)    
	CheckError("Failed to compare " + baseDocument + " and " + newDocument)
	On Error Goto 0
else
	On Error Resume Next
    Call document.Compare(baseDocument, "Comparison", wdCompareTargetNew, true, true)    
	if Err.Number <> 0 then	
    	WScript.Echo("Failed to compare " + baseDocument + " and " + newDocument)    	
    	document.Close(wdDoNotSaveChanges)
    	WScript.Quit(1)
    end if	
    On Error Goto 0
end if

'Show the comparison result
if version < Office_2007 then
	application.ActiveDocument.Windows(1).Visible = 1
end if	
  
'Mark the comparison document as saved
application.ActiveDocument.Saved = 1
    
'close the first document
if version >= Office_2002 then
    document.Close(wdDoNotSaveChanges)
end if
