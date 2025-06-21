B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
'#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\\..\\Shared Files" "..\\Files" 'JULES: Commented out to prevent build error due to missing Shared Files directory. If these files are needed, ensure C:\Users\301-PC2\Desktop\EXAMEN~1\Shared Files\ exists and contains the required files.
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
	Private BtnCargarPlanta As Button       ' Nuevo botón
	Private PanelColor As B4XView
	'----------------------------------------------------
End Sub

Public Sub Initialize
	' No es necesario inicializar nada aquí.
End Sub

Sub CreateUI
	SpinnerPlanta.Initialize("SpinnerPlanta")
	EtSuperficie.Initialize("")
	ListViewProcesos.Initialize("ListViewProcesos")
	BtnGuardar.Initialize("BtnGuardar")
	BtnGuardar.Text = "Guardar"
	BtnCargarPlanta.Initialize("BtnCargarPlanta") ' Inicializar el nuevo botón
	BtnCargarPlanta.Text = "Cargar Planta"      ' Establecer texto para el nuevo botón
	PanelColor = xui.CreatePanel("")

	' Distribución simple
	Dim gap As Int = 16dip
	Dim buttonWidth As Int = (Root.Width - 3 * gap) / 2 ' Ancho para dos botones con un espacio entre ellos
	Dim top As Int = gap
	Root.AddView(SpinnerPlanta, gap, top, Root.Width - 2 * gap, 40dip)
	top = top + SpinnerPlanta.Height + gap

	Dim lbl As Label
	lbl.Initialize("")
	lbl.Text = "Superficie (m²):"
	Root.AddView(lbl, gap, top, 200dip, 30dip)
	top = top + lbl.Height
	Root.AddView(EtSuperficie, gap, top, Root.Width - 2 * gap - 60dip, 40dip)
	PanelColor.Color = xui.Color_White
	Root.AddView(PanelColor, Root.Width - gap - 40dip, top, 40dip, 40dip)

	top = top + EtSuperficie.Height + gap
	Root.AddView(ListViewProcesos, gap, top, Root.Width - 2 * gap, Root.Height - top - 2 * gap - 40dip - 50dip) ' Ajustar altura para botones

	' Añadir botones en la parte inferior
	Root.AddView(BtnGuardar, gap, Root.Height - gap - 40dip, buttonWidth, 40dip)
	Root.AddView(BtnCargarPlanta, gap + buttonWidth + gap, Root.Height - gap - 40dip, buttonWidth, 40dip)
End Sub

' ----------------------------------------------------
' Se dispara una sola vez cuando la página se crea.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	CreateUI                                    ' Creamos la interfaz por código

	' 1) EditText sólo admite decimales
	EtSuperficie.InputType = EtSuperficie.INPUT_TYPE_DECIMAL_NUMBERS

	' 2) Base de datos SQLite
	SQL1.Initialize(File.DirInternal, "Fabrica.db", True)
	SQL1.ExecNonQuery("CREATE TABLE IF NOT EXISTS Planta(Color TEXT PRIMARY KEY, Superficie REAL, HexColor TEXT)")
	SQL1.ExecNonQuery("CREATE TABLE IF NOT EXISTS Proceso(PlantaColor TEXT, Nombre TEXT, Complejidad TEXT)")

	' 3) Datos iniciales (sólo la primera vez)
	InsertDatosIniciales

	' 4) Carga spinner y muestra datos del primer color
	CargaSpinner
	If SpinnerPlanta.Size > 0 Then
		SpinnerPlanta.SelectedIndex = 0
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

	Dim hex() As String = Array As String( _
		"#f0f8ff","#faebd7","#00ffff","#7fffd4","#f0ffff", _
		"#f5f5dc","#ffe4c4","#000000","#ffebcd","#0000ff", _
		"#8a2be2","#a52a2a","#deb887","#5f9ea0","#7fff00", _
		"#d2691e","#ff7f50","#6495ed","#fff8dc","#dc143c", _
		"#00ffff","#00008b","#008b8b","#b8860b","#a9a9a9", _
		"#006400","#bdb76b","#8b008b","#556b2f","#ff8c00", _
		"#9932cc","#8b0000","#e9967a","#8fbc8f","#483d8b", _
		"#2f4f4f","#00ced1","#9400d3","#ff1493","#00bfff", _
		"#696969","#1e90ff","#b22222","#fffaf0","#228b22", _
		"#ff00ff","#dcdcdc","#f8f8ff","#ffd700","#daa520" _
	)

	SQL1.BeginTransaction
	Try
		For i = 0 To colores.Length - 1
			Dim c As String = colores(i)
			Dim h As String = hex(i)
			SQL1.ExecNonQuery2("INSERT OR IGNORE INTO Planta(Color,Superficie,HexColor) VALUES(?,?,?)", _
				Array As Object(c, 100 + Rnd(0, 901), h))
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
	Dim rsP As ResultSet = SQL1.ExecQuery2("SELECT Superficie, HexColor FROM Planta WHERE Color=?", _
		Array As String(ColorPlanta))
	If rsP.NextRow Then
		EtSuperficie.Text = NumberFormat(rsP.GetDouble("Superficie"), 0, 2)
		Dim hx As String = rsP.GetString("HexColor")
		PanelColor.Color = HexToColor(hx)
	Else
		EtSuperficie.Text = ""
		PanelColor.Color = xui.Color_White
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

' Evento para el nuevo botón Cargar Planta
Sub BtnCargarPlanta_Click
    Dim Plantas As List
    Plantas.Initialize
    Dim rs As ResultSet = SQL1.ExecQuery("SELECT Color FROM Planta ORDER BY Color")
    Do While rs.NextRow
        Plantas.Add(rs.GetString("Color"))
    Loop
    rs.Close

    If Plantas.Size = 0 Then
        xui.MsgboxAsync("No hay plantas para cargar.", "Información")
        Return
    End If

    Dim id As InputDialog
    id.Initialize
    Dim sf As Object = id.ShowList(Plantas, "Seleccione una planta", True, xui.DialogResponse_Cancel)
    Wait For (sf) Dialog_Result(Result As Int)

    If Result = xui.DialogResponse_Positive Then
        Dim ItemIndex As Int = id.SelectedItemIndex
        If ItemIndex > -1 And ItemIndex < Plantas.Size Then
            Dim PlantaSeleccionada As String = Plantas.Get(ItemIndex)
            MostrarDatos(PlantaSeleccionada)

            For i = 0 To SpinnerPlanta.Size - 1
                If SpinnerPlanta.GetItem(i) = PlantaSeleccionada Then
                    SpinnerPlanta.SelectedIndex = i
                    Exit
                End If
            Next
        Else
             Log("Índice de planta seleccionada no válido o no se seleccionó ninguna planta.")
        End If
    Else
        Log("Carga de planta cancelada por el usuario.")
    End If
End Sub

' Cierra la conexión cuando la página se cierre
Private Sub B4XPage_CloseRequest As ResumableSub
	SQL1.Close
	Return True
End Sub

Sub HexToColor(hex As String) As Int
	If hex.StartsWith("#") Then hex = hex.SubString(1)
	Dim c As Long = Bit.ParseInt(hex, 16)
	If hex.Length = 6 Then c = Bit.Or(c, 0xFF000000)
	Return c
End Sub
