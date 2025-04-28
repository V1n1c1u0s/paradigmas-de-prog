program MorseConverter;

{$mode objfpc}{$H+}

uses
    glib2, gtk2, gdk2, crt, SysUtils, Unix, Classes, Math;

const
    MUnit = 0.1; {seconds}
    SampleRate = 44100;
    Frequency = 800; (*Hz*)
    DotDuration = MUnit;  // seconds
    DashDuration = MUnit*3;
    SymbolSpace = MUnit;
    LetterSpace = MUnit*3;
    
    Alfabeto: array[1..49] of Char =
        ('A','B','C','D','E','F','G','H','I','J','K','L','M',
        'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
        '0','1','2','3','4','5','6','7','8','9',
        '.',',',':','?','''','-','/','(',')','=','+', '*', '@');

    Morse: array[1..49] of String =
        ('.-', '-...', '-.-.', '-..', '.', '..-.', '--.', '....', '..', '.---',
        '-.-', '.-..', '--', '-.', '---', '.--.', '--.-', '.-.', '...', '-',
        '..-', '...-', '.--', '-..-', '-.--', '--..',
        '-----', '.----', '..---', '...--', '....-', '.....',
        '-....', '--...', '---..', '----.',
        '.-.-.-','--..--','---...','..--..','.----.','-....-','-..-.',
        '-.--.','-.--.-','-...-','.-.-.','-..-','.--.-.');

var
    window, button, vbox, hbox1, hbox2, morse_label, morse_entry, 
    morse_audio_btn, text_label, text_entry, header_bar, header_label, close_button: pGtkWidget;

function GetMorse(c: Char): String;
var
    i: Integer;
begin
    for i := 1 to 49 do
        if Alfabeto[i] = c then
        Exit(Morse[i]);
    Result := ''; // Ignora desconhecido
end;

procedure AppendTone(var Data: TMemoryStream; Duration: Double);
var
    i, SampleCount: Integer;
    Sample: SmallInt;
    Angle: Double;
begin
    SampleCount := Round(SampleRate * Duration);
    for i := 0 to SampleCount - 1 do
    begin
        Angle := 2 * Pi * Frequency * i / SampleRate;
        Sample := Round(Sin(Angle) * 32767); //16bits
        Data.Write(Sample, SizeOf(Sample));
    end;
end;

procedure AppendSilence(var Data: TMemoryStream; Duration: Double);
var
    i, SampleCount: Integer;
    Sample: SmallInt;
begin
    Sample := 0;
    SampleCount := Round(SampleRate * Duration);
    for i := 0 to SampleCount - 1 do
        Data.Write(Sample, SizeOf(Sample));
end;

procedure SaveWav(Data: TMemoryStream; const FileName: String);
var
    OutFile: TFileStream;
    DataSize, RiffSize: Integer;
    Header: array[0..43] of Byte;
begin
    DataSize := Data.Size;
    RiffSize := DataSize + 36;
    FillChar(Header, SizeOf(Header), 0);
    Move('RIFF', Header[0], 4);
    PInteger(@Header[4])^ := RiffSize;
    Move('WAVEfmt ', Header[8], 8);
    PInteger(@Header[16])^ := 16; // PCM
    PWord(@Header[20])^ := 1; // Format: PCM linear
    PWord(@Header[22])^ := 1; // Channels - mono
    PInteger(@Header[24])^ := SampleRate; // Taxa de Amostragem
    PInteger(@Header[28])^ := SampleRate * 1 * 2; // Byte Rate - SampleRate * channels * 2(bytes (16 bits por amostra))
    PWord(@Header[32])^ := 2; //Block Align - Channels * 2 bytes
    PWord(@Header[34])^ := 16; //cada amostra tem 16 bits
    Move('data', Header[36], 4); //inicio dos dados do audio
    PInteger(@Header[40])^ := DataSize; //tamanho real dos dados de áudio (sem o cabeçalho)

    OutFile := TFileStream.Create(FileName, fmCreate);
    try
        OutFile.WriteBuffer(Header, SizeOf(Header));
        OutFile.CopyFrom(Data, 0);
    finally
        OutFile.Free;
    end;
end;

procedure TextoParaAudio(const Texto: String; const OutputFile: String);
var
    i, j: Integer;
    MorseCode: String;
    Stream: TMemoryStream;
    c, s: Char;
begin
    Stream := TMemoryStream.Create;
    try
        for i := 1 to Length(Texto) do
        begin
            c := UpCase(Texto[i]);
            if c = ' ' then
                AppendSilence(Stream, LetterSpace)
            else
            begin
                MorseCode := GetMorse(c);
                for j := 1 to Length(MorseCode) do
                begin
                s := MorseCode[j];
                if s = '.' then
                    AppendTone(Stream, DotDuration)
                else if s = '-' then
                    AppendTone(Stream, DashDuration);
                    AppendSilence(Stream, SymbolSpace);
                end;
            AppendSilence(Stream, LetterSpace);
            end;
        end;
        SaveWav(Stream, OutputFile);
    finally
        Stream.Free;
    end;
end;

procedure destroy(widget: PGtkWidget; data: pgpointer); cdecl;
begin
    gtk_main_quit();
end;

function ParaMorse(Texto: String): String;
var
    i, j: Integer;
    c: Char;
    Resultado: String;
begin
    Resultado := '';
    Texto := UpperCase(Texto);

    for i := 1 to Length(Texto) do
    begin
        c := Texto[i];
        if c = ' ' then
            Resultado := Resultado + ' / '
        else
        begin
            for j := 1 to 49 do
            if Alfabeto[j] = c then
            begin
                Resultado := Resultado + Morse[j] + ' ';
                Break;
            end;
        end;
    end;
    TextoParaAudio(Texto, '/tmp/morse.wav');
    ParaMorse := Trim(Resultado);
end;

procedure on_convert_button_click(widget: PGtkWidget; data: gpointer); cdecl;
var
    input_text, morse_text: String;
begin
    input_text := gtk_entry_get_text(GTK_ENTRY(text_entry));

    morse_text := ParaMorse(input_text);

    gtk_entry_set_text(GTK_ENTRY(morse_entry), PChar(morse_text));
end;

procedure play_audio(widget: PGtkWidget; data: gpointer); cdecl;
begin
    fpsystem('aplay /tmp/morse.wav');
end;

begin
    gtk_init(@argc, @argv);

    window := gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), 'Conversor de Morse');
    gtk_window_set_default_size(GTK_WINDOW(window), 400, 250);
    gtk_container_set_border_width(GTK_CONTAINER(window), 20);
    gtk_window_set_type_hint(GTK_WINDOW(window), GDK_WINDOW_TYPE_HINT_DIALOG);


    vbox := gtk_vbox_new(FALSE, 0);
    gtk_container_add(GTK_CONTAINER(window), vbox);

    header_bar := gtk_hbox_new(FALSE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), header_bar, FALSE, FALSE, 15);

    header_label := gtk_label_new('Conversor de Morse');
    gtk_box_pack_start(GTK_BOX(header_bar), header_label, TRUE, TRUE, 5);

    close_button := gtk_button_new_with_label('✖');
    gtk_box_pack_end(GTK_BOX(header_bar), close_button, FALSE, FALSE, 5);

    g_signal_connect(G_OBJECT(close_button), 'clicked', TGCALLBACK(@destroy), nil);

    hbox1 := gtk_hbox_new(FALSE, 5);
    gtk_box_pack_start(GTK_BOX(vbox), hbox1, TRUE, TRUE, 0);

    text_label := gtk_label_new('Texto');
    gtk_box_pack_start(GTK_BOX(hbox1), text_label, FALSE, FALSE, 5);

    text_entry := gtk_entry_new();
    gtk_box_pack_start(GTK_BOX(hbox1), text_entry, TRUE, TRUE, 5);

    hbox2 := gtk_hbox_new(FALSE, 5);
    gtk_box_pack_start(GTK_BOX(vbox), hbox2, TRUE, TRUE, 0);

    morse_label := gtk_label_new('Morse');
    gtk_box_pack_start(GTK_BOX(hbox2), morse_label, FALSE, FALSE, 5);

    morse_entry := gtk_entry_new();
    gtk_box_pack_start(GTK_BOX(hbox2), morse_entry, TRUE, TRUE, 5);

    morse_audio_btn := gtk_button_new_with_label('▶️ Play');
    gtk_box_pack_start(GTK_BOX(vbox), morse_audio_btn, FALSE, FALSE, 5);

    button := gtk_button_new_with_label('Converter');
    gtk_box_pack_start(GTK_BOX(vbox), button, FALSE, FALSE, 5);

    g_signal_connect(G_OBJECT(window), 'destroy', TGCALLBACK(@destroy), NULL);
    g_signal_connect(G_OBJECT(button), 'clicked', TGCALLBACK(@on_convert_button_click), NULL);
    g_signal_connect(G_OBJECT(morse_audio_btn), 'clicked', TGCALLBACK(@play_audio), NULL);

    gtk_widget_show_all(window);
    gtk_main();
end.
