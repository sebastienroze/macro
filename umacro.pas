unit umacro;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls;

type

  { TfMacro }

  TfMacro = class(TForm)
    BtVider: TButton;
    CbActif: TCheckBox;
    CbEnreg: TCheckBox;
    EdRepete: TEdit;
    Label1: TLabel;
    LbTouche: TListBox;
    Memo1: TMemo;
    RgToucheF: TRadioGroup;
    procedure BtViderClick(Sender: TObject);
    procedure CbActifChange(Sender: TObject);
    procedure CbActifClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure RgToucheFClick(Sender: TObject);
  private
    { private declarations }
  public
    procedure JoueMacro;
    { public declarations }
  end;

  OTouche = Class(TObject)
     Vk_Touche : integer;
     bToucheup : boolean;
  end;

var
  fMacro: TfMacro;
  TouchePrec : OTouche;

implementation

{$R *.lfm}

uses
  Variants, ComObj, LCLIntf, LCLType,Clipbrd,mouseandkeyinput,windows ;

{ TfMacro }

const
  wh_keybd_ll = 13;

type
    KeybdLLHookStruct = record
        vkCode      : cardinal;
        scanCode    : cardinal;
        flags       : cardinal;
        time        : cardinal;
        dwExtraInfo : cardinal;
      end;

var
  mHook : cardinal;
  kHook : cardinal;
  Vk_ToucheActive : integer;



function GetCharFromVirtualKey(Key: Word): String;
  var
    keyboardState: TKeyboardState;
    asciiResult: Integer;
  begin
    GetKeyboardState(keyboardState) ;

    SetLength(Result, 2) ;
    asciiResult := ToAscii(key, MapVirtualKey(key, 0), keyboardState, @Result[1], 0) ;
    case asciiResult of
      0: Result := '';
      1: SetLength(Result, 1) ;
      2:;
      else
        Result := '';
    end;
  end;

function LowLevelKeybdHookProc(nCode: LongInt; WPARAM: WPARAM;
  lParam: LPARAM): LRESULT; stdcall;
// possible wParam values: WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP
var
info : ^KeybdLLHookStruct absolute lParam;
//lpChar : word;
kState : TKeyboardState;
latouche : OTouche;
sNomTouche : string;
KeyName: array[0..255] of Char;

begin
    result := CallNextHookEx(kHook, nCode, wParam, lParam);
    with info^ do
    begin
      GetKeyboardState(kState);
      if fMacro.CbEnreg.Checked = true then
      begin
          latouche := OTouche.Create;
          latouche.Vk_Touche := vkCode;
          latouche.bToucheup:= (wParam =  wm_keyup );

//          GetKeyNameTextA(vkCode, KeyName, SizeOf(KeyName));
          sNomTouche :=GetCharFromVirtualKey(vkCode) ;
          if latouche.bToucheup = true then sNomTouche:= sNomTouche+ ' ↑'
          else sNomTouche:= sNomTouche+ ' ↓';

//          GetKeyNameText( MapVirtualKey(vkCode, 0), KeyName, SizeOf(KeyName));
//          sNomTouche := intToStr(vkcode);

//          MapVirtualKey(Int64Rec(wParam).lo, 0) shl 16;
//          fMacro.ltouches.Add(sNomTouche(lParam,  latouche);
          if (TouchePrec.bToucheup<> latouche.bToucheup) or (TouchePrec.Vk_Touche<> latouche.Vk_Touche) then
                    fMacro.LbTouche.Items.AddObject(sNomTouche, latouche);
          TouchePrec.bToucheup:= latouche.bToucheup;
          TouchePrec.Vk_Touche:= latouche.Vk_Touche;

      end;
      if (fMacro.CbActif.Checked = true) and (wParam =  wm_keyup ) and (vkCode = Vk_ToucheActive) then
      begin
          fMacro.JoueMacro;
{              if Fcoller.Memo1.Lines.Count> 0 then
              begin
                  Clipboard.AsText := Fcoller.Memo1.Lines[0];
                  Fcoller.Memo1.Lines.Delete(0) ;
                  Application.ProcessMessages;
                  Keybd_event(VK_RCONTROL,$9e,0,0);
                  Keybd_event(VKKeyScan('v') ,$9e,0,0);
                  Keybd_event(VKKeyScan('v'),$9e,KEYEVENTF_KEYUP,0);
                  Keybd_event(VK_RCONTROL,$9e,KEYEVENTF_KEYUP,0);
//                  Keybd_event(VK_RCONTROL,0,$9e,KEYEVENTF_KEYUP);
              end; }

      end;
    end;
end;

procedure TfMacro.CbActifChange(Sender: TObject);
begin
end;

procedure TfMacro.BtViderClick(Sender: TObject);
begin
  while  LbTouche.Items.Count > 0 do
  begin
       LbTouche.Items.Objects[0].Free;
       LbTouche.Items.Delete(0);
       TouchePrec.Vk_Touche:= 0;
       TouchePrec.bToucheup:= false;
  end;
end;

procedure TfMacro.CbActifClick(Sender: TObject);
begin
  Vk_ToucheActive:= VK_F1 + RgToucheF.ItemIndex;
end;

procedure TfMacro.FormCreate(Sender: TObject);
begin
  TouchePrec :=OTouche.Create;
  TouchePrec.Vk_Touche:= 0;
  TouchePrec.bToucheup:= false;
  kHook := SetWindowsHookEx(wh_keybd_ll, @LowLevelKeybdHookProc, hInstance, 0);
  RgToucheFClick(self);
end;

procedure TfMacro.FormDestroy(Sender: TObject);
begin
  TouchePrec.Free;
end;

procedure TfMacro.RgToucheFClick(Sender: TObject);
begin
      Vk_ToucheActive:= VK_F1 + RgToucheF.ItemIndex;
end;

procedure TfMacro.JoueMacro;
var i,rep,nbrep : integer;
latouche : OTouche;

begin
  try
    nbrep := StrToInt(EdRepete.Text);
  except
    nbrep := 1;
  end;
  for rep := 1 to nbrep do
  for i := 0 to LbTouche.Count -1 do
  begin
    latouche := OTouche(LbTouche.Items.Objects[i]);
    if latouche.bToucheup = false then
       Keybd_event(latouche.Vk_Touche ,$9e,0,0)
    else
        Keybd_event(latouche.Vk_Touche,$9e,KEYEVENTF_KEYUP,0);
    sleep(5);
  end;
end;

end.

