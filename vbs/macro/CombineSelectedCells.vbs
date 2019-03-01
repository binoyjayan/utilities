' Macro to merge selected cells and copy it to the first cell.
' 
' Shortcut - Ctrl Shift C
'

Sub CombineSelectedCells()
    Dim cell As Range
    Dim CombinedEntry As String
 
'   Loop through selection and build string and erase values in cells being merged
    For Each cell In Selection
        CombinedEntry = CombinedEntry & cell.Value & Chr(10)
        cell.ClearContents
    Next cell
 
'   Remove last space from string
    CombinedEntry = Left(CombinedEntry, Len(CombinedEntry) - 1)
 
'   Merge cells and populate entry
'   Selection.Merge
'   ActiveCell.Value = CombinedEntry

'   Copy combined value to first cell
    Selection(1).Value = CombinedEntry
End Sub



