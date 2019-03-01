' Delete the empty rows in the selection if the whole row is empty
' 
' Shortcut - Ctrl Shift D
'

Sub DeleteEmptyRows()
	Dim aRow As Range
	Dim BlankRows As Range
	For Each aRow In Selection.Rows.EntireRow
		If WorksheetFunction.CountA(aRow) = 0 Then
			If Not BlankRows Is Nothing Then
				Set BlankRows = Union(BlankRows, aRow)
			Else
				Set BlankRows = aRow
			End If
		End If
	Next
	If Not BlankRows Is Nothing Then
		Application.ScreenUpdating = False
		BlankRows.Delete
		Application.ScreenUpdating = True
	End If
End Sub
