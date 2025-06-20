B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\\..\\Shared Files" "..\\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\\..\\Shared+Files&args=..\\Files&FilesSync=True
#End Region

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	'----------------------------------------------------
	' Variables globales:
	Private SQL1 As SQL
	Private SpinnerPlanta As Spinner        ' WithEvents en el diseñador
	Private EtSuperficie As EditText
	Private ListViewProcesos As ListView
	Private BtnGuardar As Button            ' WithEvents en el diseñador
	'----------------------------------------------------
End Sub

Public Sub Initialize
	' No es necesario inicializar nada aquí.
End Sub

' ----------------------------------------------------
' Se dispara una sola vez cuando la página se crea.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")            ' Carga MainPage.bal

	' 1) EditText sólo admite decimales
	EtSuperficie.InputType = EtSuperficie.INPUT_TYPE_DECIMAL_NUMBERS

	' 2) Base de datos SQLite
	SQL1.Initialize(File.DirInternal, "Fabrica.db", True)
	SQL1.ExecNonQuery("CREATE TABLE IF NOT EXISTS Planta(Color TEXT PRIMARY KEY, Superficie REAL)")
	SQL1.ExecNonQuery("CREATE TABLE IF NOT EXISTS Proceso(PlantaColor TEXT, Nombre TEXT, Complejidad TEXT)")

	' 3) Datos iniciales (sólo la primera vez)
	InsertDatosIniciales

	' 4) Carga spinner y muestra datos del primer color
	CargaSpinner
	If SpinnerPlanta.Size > 0 Then
		SpinnerPlanta.SelectedIndex = 0
		' Provocamos el mismo evento para mostrar la primera planta
		SpinnerPlanta_ItemClick(0, SpinnerPlanta.GetItem(0))
	End If
End Sub

' Inserta 50 colores y dos procesos por cada planta
Sub InsertDatosIniciales
	Dim colores() As String = Array As String( _
        "AliceBlue","AntiqueWhite","Aqua","Aquamarine","Azure", _
        "Beige","Bisque","Black","BlanchedAlmond","Blue", _
        "BlueViolet","Brown","BurlyWood","CadetBlue","Chartreuse", _
        "Chocolate","Coral","CornflowerBlue","Cornsilk","Crimson", _
        "Cyan","DarkBlue","DarkCyan","DarkGoldenRod","DarkGray", _
        "DarkGreen","DarkKhaki","DarkMagenta","DarkOliveGreen","DarkOrange", _
        "DarkOrchid","DarkRed","DarkSalmon","DarkSeaGreen","DarkSlateBlue", _
        "DarkSlateGray","DarkTurquoise","DarkViolet","DeepPink","DeepSkyBlue", _
        "DimGray","DodgerBlue","FireBrick","FloralWhite","ForestGreen", _
        "Fuchsia","Gainsboro","GhostWhite","Gold","GoldenRod" _
    )

	SQL1.BeginTransaction
	Try
		For Each c As String In colores
			SQL1.ExecNonQuery2("INSERT OR IGNORE INTO Planta(Color,Superficie) VALUES(?,?)", _
                Array As Object(c, 100 + Rnd(0, 901)))
			SQL1.ExecNonQuery2("INSERT OR IGNORE INTO Proceso(PlantaColor,Nombre,Complejidad) VALUES(?,?,?)", _
                Array As Object(c, "Corte", "Alto"))
			SQL1.ExecNonQuery2("INSERT OR IGNORE INTO Proceso(PlantaColor,Nombre,Complejidad) VALUES(?,?,?)", _
                Array As Object(c, "Moldeo", "Medio"))
		Next
		SQL1.TransactionSuccessful
	Catch
		Log(LastException)
	End Try
	SQL1.EndTransaction
End Sub


' Llena el spinner con los colores existentes
Sub CargaSpinner
	SpinnerPlanta.Clear
	Dim rs As ResultSet = SQL1.ExecQuery("SELECT Color FROM Planta ORDER BY Color")
	Do While rs.NextRow
		SpinnerPlanta.Add(rs.GetString("Color"))
	Loop
	rs.Close
End Sub

' Evento al seleccionar un color
Sub SpinnerPlanta_ItemClick (Position As Int, Value As Object)
	MostrarDatos(Value)   ' Value es String porque lo añadimos como tal al Spinner
End Sub

' Muestra superficie y lista de procesos para la planta elegida
Sub MostrarDatos(ColorPlanta As String)
	' --- Superficie ---
	Dim rsP As ResultSet = SQL1.ExecQuery2("SELECT Superficie FROM Planta WHERE Color=?", _
        Array As String(ColorPlanta))
	If rsP.NextRow Then
		EtSuperficie.Text = NumberFormat(rsP.GetDouble("Superficie"), 0, 2)
	Else
		EtSuperficie.Text = ""
	End If
	rsP.Close

	' --- Procesos ---
	ListViewProcesos.Clear
	Dim rsPr As ResultSet = SQL1.ExecQuery2("SELECT Nombre,Complejidad FROM Proceso WHERE PlantaColor=?", _
        Array As String(ColorPlanta))
	Do While rsPr.NextRow
		ListViewProcesos.AddTwoLines(rsPr.GetString("Nombre"), rsPr.GetString("Complejidad"))
	Loop
	rsPr.Close
End Sub

' Guarda la nueva superficie
Sub BtnGuardar_Click
	Dim s As String = EtSuperficie.Text.Trim.Replace(",", ".")
	If s.Length = 0 Or IsNumber(s) = False Then
		xui.MsgboxAsync("Introduce un número decimal válido (ej. 123.45)", "Dato incorrecto")
		Return
	End If

	Dim sup As Double = s
	Dim colorSel As String = SpinnerPlanta.GetItem(SpinnerPlanta.SelectedIndex)
	SQL1.ExecNonQuery2("UPDATE Planta SET Superficie=? WHERE Color=?", Array As Object(sup, colorSel))
	ToastMessageShow("Superficie guardada", False)
End Sub


' Cierra la conexión cuando la página se cierre
Private Sub B4XPage_CloseRequest As ResumableSub
	SQL1.Close
	Return True
End Sub

