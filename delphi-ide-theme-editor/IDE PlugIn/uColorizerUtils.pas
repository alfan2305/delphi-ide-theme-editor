{**************************************************************************************************}
{                                                                                                  }
{ Unit uColorizerUtils                                                                             }
{ unit uColorizerUtils  for the Delphi IDE Colorizer                                               }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is uColorizerUtils.pas.                                                        }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2011 Rodrigo Ruz V.                         }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}

unit uColorizerUtils;

interface

uses
 {$IF CompilerVersion >= 23}
 VCL.Themes,
 VCL.Styles,
 {$IFEND}
 XPMan,
 ActnMan,
 ActnColorMaps,
 Graphics,
 uClrSettings,
 Classes;

procedure RefreshIDETheme(AColorMap:TCustomActionBarColorMap);
procedure LoadSettings(AColorMap:TCustomActionBarColorMap;Settings : TSettings);
procedure ProcessComponent(AColorMap:TCustomActionBarColorMap;AComponent: TComponent);
procedure GenerateColorMap(AColorMap:TCustomActionBarColorMap;Color:TColor);{$IF CompilerVersion >= 23}overload;{$IFEND}
{$IF CompilerVersion >= 23}
procedure GenerateColorMap(AColorMap:TCustomActionBarColorMap;Style:TCustomStyleServices);overload;
{$IFEND}

function  GetBplLocation : string;


var
  DelphiTheme   : TXPManifest;
  GlobalColorMap: TXPColorMap;
  HookedWindows : TStringList;
  GlobalSettings: TSettings;

implementation

{.$DEFINE DEBUG_MODE}
{.$DEFINE DEBUG_PROFILER}

uses
 {$IF CompilerVersion >= 23}
 uVCLStyleUtils,
 {$IFEND}
 {$IF CompilerVersion > 20}
 Rtti
 {$ELSE}
 Variants,
 TypInfo
 {$IFEND},
 Types,
 Forms,
 Menus,
 Tabs,
 ComCtrls,
 Controls,
 StdCtrls,
 SysUtils,
 ExtCtrls,
 GraphUtil,
 UxTheme,
 CategoryButtons,
 XPStyleActnCtrls,
 ActnCtrls,
 ActnMenus,
 uStoreColorMap,
 Dialogs,
 Windows,
 uRttiHelper;



{$IFDEF DEBUG_MODE}
  lcomp         : TStringList;
{$ENDIF}

{$IFDEF DEBUG_PROFILER}
var
  lprofiler     : TStringList;
  lpignored     : TStringList;
  lDumped       : TStringList;
{$ENDIF}

{$IF CompilerVersion > 20}
var
  ctx           : TRttiContext;
{$IFEND}
  //Drawer        : TComponentDrawer;


{$IFDEF DEBUG_PROFILER}
procedure DumpComponent(AComponent: TComponent);
var
l2 : TStrings;
begin
  l2 := TStringList.Create;
  try
   l2.Text:=DumpTypeDefinition(AComponent.ClassInfo);
  finally
   l2.SaveToFile(ExtractFilePath(GetBplLocation())+'Galileo\'+AComponent.ClassName+'.pas');
   l2.Free;
  end;
end;
{$ENDIF}

function  GetBplLocation : string;
begin
  SetLength(Result,MAX_PATH);
  GetModuleFileName(HInstance,PChar(Result),MAX_PATH);
  Result:=PChar(Result);
end;


procedure RefreshIDETheme(AColorMap:TCustomActionBarColorMap);
var
  index     : Integer;
begin
 {
  if GlobalSettings.EnableDWMColorization and DwmIsEnabled then
   SetCompositionColor(AColorMap.Color);
 }
  for Index := 0 to Screen.FormCount-1 do
  if HookedWindows.IndexOf(Screen.Forms[Index].ClassName)<>-1 then
  begin
   if not (csDesigning in Screen.Forms[Index].ComponentState) then
     ProcessComponent(AColorMap,Screen.Forms[Index]);
  end
  {$IF CompilerVersion >= 23}
  else
  if (csDesigning in Screen.Forms[index].ComponentState) then
    ApplyEmptyVCLStyleHook(Screen.Forms[index].ClassType);
  {$IFEND}
end;


procedure LoadSettings(AColorMap:TCustomActionBarColorMap;Settings : TSettings);
Var
 ThemeFileName : string;
begin
  ReadSettings(Settings, ExtractFilePath(GetBplLocation()));
  ThemeFileName:=IncludeTrailingPathDelimiter(ExtractFilePath(GetBplLocation()))+'Themes\'+Settings.ThemeName+'.idetheme';
  if FileExists(ThemeFileName) then
   LoadColorMapFromXmlFile(TXPColorMap(AColorMap),ThemeFileName);
end;


procedure GenerateColorMap(AColorMap:TCustomActionBarColorMap;Color:TColor);
begin
{
+    property ShadowColor default cl3DDkShadow;
+    property Color default clBtnFace;
    property DisabledColor default clGray;
    property DisabledFontColor default clGrayText;
    property DisabledFontShadow default clBtnHighlight;
    property FontColor default clWindowText;
+    property HighlightColor;
    property HotColor default clDefault;
    property HotFontColor default clDefault;
    property MenuColor default clWindow;
+    property FrameTopLeftInner default clWhite;
+    property FrameTopLeftOuter default cXPFrameOuter;
+    property FrameBottomRightInner default clWhite;
+    property FrameBottomRightOuter default cXPFrameOuter;
+    property BtnFrameColor default cXPBtnFrameColor;
+    property BtnSelectedColor default clWhite;
+    property BtnSelectedFont default clWindowText;
+    property SelectedColor default cXPSelectedColor;
+    property SelectedFontColor default clBlack;
    property UnusedColor;
}
  AColorMap.Color                 :=Color;
  AColorMap.ShadowColor           :=GetShadowColor(Color);

  AColorMap.MenuColor             :=GetHighLightColor(Color);
  AColorMap.HighlightColor        :=GetHighLightColor(AColorMap.MenuColor);
  AColorMap.BtnSelectedColor      :=Color;
  AColorMap.BtnSelectedFont       :=AColorMap.FontColor;

  AColorMap.SelectedColor         :=GetHighLightColor(Color,50);
  AColorMap.SelectedFontColor     :=AColorMap.FontColor;

  AColorMap.BtnFrameColor         :=GetShadowColor(Color);
  AColorMap.FrameTopLeftInner     :=GetShadowColor(Color);
  AColorMap.FrameTopLeftOuter     :=AColorMap.FrameTopLeftInner;
  AColorMap.FrameBottomRightInner :=AColorMap.FrameTopLeftInner;
  AColorMap.FrameBottomRightOuter :=AColorMap.FrameTopLeftInner;
end;

{$IF CompilerVersion >= 23}
procedure GenerateColorMap(AColorMap:TCustomActionBarColorMap;Style:TCustomStyleServices);
begin
  AColorMap.Color                 :=Style.GetStyleColor(scPanel);
  AColorMap.ShadowColor           :=GetShadowColor(AColorMap.Color);
  AColorMap.FontColor             :=Style.GetStyleFontColor(sfButtonTextNormal);

  AColorMap.MenuColor             :=AColorMap.Color;
  AColorMap.HighlightColor        :=GetHighLightColor(AColorMap.MenuColor);
  AColorMap.BtnSelectedColor      :=AColorMap.Color;
  AColorMap.BtnSelectedFont       :=AColorMap.FontColor;

  AColorMap.SelectedColor         :=GetHighLightColor(AColorMap.Color,50);
  AColorMap.SelectedFontColor     :=AColorMap.FontColor;

  AColorMap.BtnFrameColor         :=GetShadowColor(AColorMap.Color);
  AColorMap.FrameTopLeftInner     :=GetShadowColor(AColorMap.Color);
  AColorMap.FrameTopLeftOuter     :=AColorMap.FrameTopLeftInner;
  AColorMap.FrameBottomRightInner :=AColorMap.FrameTopLeftInner;
  AColorMap.FrameBottomRightOuter :=AColorMap.FrameTopLeftInner;
end;
{$IFEND}




//check these windows when an app is debuged
function SkinDebuggerWindows(AColorMap:TCustomActionBarColorMap;AComponent: TComponent) : Boolean;
const
  NumWin  = 4;
  CompList : array  [0..NumWin-1] of string = ('TDisassemblerView','TRegisterView','TFlagsView','TDumpView');
var
  Index : Integer;
begin
   Result:=False;
  for Index := 0 to NumWin-1 do
    if CompareText(AComponent.ClassName,CompList[Index])=0 then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.MenuColor);
      Result:=True;
      Break;
    end
end;

function SkinVclControls(AColorMap:TCustomActionBarColorMap;AComponent: TComponent) : Boolean;
const
  NumWin  = 7;
  CompList : array  [0..NumWin-1] of string = ('TMemo','TListView','TTreeView','TListBox','TCheckListBox','TExplorerCheckListBox','THintListView');
var
  Index : Integer;
begin
   Result:=False;
  for Index := 0 to NumWin-1 do
    if CompareText(AComponent.ClassName,CompList[Index])=0 then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.HighlightColor);
      SetRttiPropertyValue(AComponent,'Ctl3D',False);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
      Result:=True;
      Break;
    end
end;

//todo color themed tcheckbox , tradiobutton
function SkinStdVclControls(AColorMap:TCustomActionBarColorMap;AComponent: TComponent) : Boolean;
const
  NumWin  = 2;
  CompList : array  [0..NumWin-1] of string = ('TLabel','TCheckBox');
var
  Index : Integer;
begin
   Result:=False;
  for Index := 0 to NumWin-1 do
    if CompareText(AComponent.ClassName,CompList[Index])=0 then
    begin
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
      Result:=True;
      Break;
    end
end;

function SkinVclGroupControls(AColorMap:TCustomActionBarColorMap;AComponent: TComponent) : Boolean;
const
  NumWin  = 3;
  CompList : array  [0..NumWin-1] of string = ('TGroupBox','TRadioGroup','TPropRadioGroup');
var
  Index : Integer;
begin
   Result:=False;
  for Index := 0 to NumWin-1 do
    if CompareText(AComponent.ClassName,CompList[Index])=0 then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.HighlightColor);
      SetRttiPropertyValue(AComponent,'Ctl3D',False);
      SetRttiPropertyValue(AComponent,'ParentBackGround',True);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
      Result:=True;
      Break;
    end
end;

procedure ProcessComponent(AColorMap:TCustomActionBarColorMap;AComponent: TComponent);
var
  I     : Integer;
{$IF CompilerVersion > 20}
  f     : TRttiField;
{$IFEND}
begin

 if not Assigned(AComponent) then  exit;
 if not Assigned(AColorMap) then  exit;


{$IFDEF DEBUG_PROFILER}
 lprofiler.Add(Format('%s Processing component %s:%s',[formatdatetime('hh:nn:ss.zzz',Now) ,AComponent.Name,AComponent.ClassName]));
  if lDumped.IndexOf(AComponent.ClassName)=-1 then
  begin
    lDumped.Add(AComponent.ClassName);
    DumpComponent(AComponent);
  end;
{$ENDIF}


        {
 if CompareText('TDefaultEnvironmentDialog',AComponent.ClassName)=0 then exit;
           }


{$IFDEF DEBUG_MODE}
 //lcomp.Add(Format('%s : %s',[AComponent.Name,AComponent.ClassName]));
{$ENDIF}


   //todo fix colors
    if AComponent is TCategoryButtons then //Name='TIDECategoryButtons' then
    with  TCategoryButtons(AComponent) do
    begin
      Color:=AColorMap.MenuColor;
      BackgroundGradientColor:=AColorMap.MenuColor;
      ButtonOptions:=ButtonOptions+[boGradientFill];

      for i := 0 to Categories.Count-1 do
         Categories[i].Color:=AColorMap.Color;

      Font.Color:=AColorMap.FontColor;
    end
    else
    if AComponent.ClassName='TTDStringGrid' then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'Ctl3D',False);
      SetRttiPropertyValue(AComponent,'FixedColor',AColorMap.Color);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
      SetRttiPropertyValue(AComponent,'GradientStartColor',AColorMap.Color);
      SetRttiPropertyValue(AComponent,'GradientEndColor',AColorMap.Color);
    end
    else
    if AComponent.ClassName='THintListView' then
    begin

    end
    else
    if AComponent.ClassName='TPropertySheetControl' then
    begin

    end
    else
    if AComponent.ClassName='TEdit' then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.HighlightColor);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
    end
    else
    if AComponent.ClassName='TComboBox' then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.HighlightColor);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
    end
    else
    if AComponent  is TForm then   //check for descendent classes
    with TForm(AComponent) do
    begin
      Color := AColorMap.Color;
      Font.Color:=AColorMap.FontColor;
    end
    else
    if AComponent.ClassName='TPanel' then
    with TPanel(AComponent) do
    begin
      {
      Color      := AColorMap.Color;
      Ctl3D      := False;
      BevelInner := bvNone;
      BevelOuter := bvNone;
      //Repaint;
      //BevelKind  := bkFlat;
      }
    end
    else
    if AComponent.ClassName='TPageControl' then
    with TPageControl(AComponent) do
    begin
      {
      if OwnerDraw=False then
      begin
        SetWindowTheme(TPageControl(AComponent).Handle,'','');
        OwnerDraw:=True;
        TPageControl(AComponent).OnDrawTab:=Drawer.PageControlDrawTab;
      end;
      }
    end
    else
    if SkinStdVclControls(AColorMap,AComponent) then
    else
    if SkinVclControls(AColorMap,AComponent) then
    else
    if SkinDebuggerWindows(AColorMap,AComponent) then
    else
    if SkinVclGroupControls(AColorMap,AComponent) then
    else
    if AComponent.ClassName='TInspListBox' then
    begin
      {
       property BackgroundColor: TColor;
       property PropNameColor: TColor;
       property PropValueColor: TColor;
       property EditBackgroundColor: TColor;
       property EditValueColor: TColor;
       property CategoryColor: TColor;
       property GutterColor: TColor;
       property GutterEdgeColor: TColor;
       property ReferenceColor: TColor;
       property SubPropColor: TColor;
       property ReadOnlyColor: TColor;
       property NonDefaultColor: TColor;
       property HighlightColor: TColor;
       property HighlightFontColor: TColor;
      }
      SetRttiPropertyValue(AComponent,'EditBackgroundColor',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'HighlightColor',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'BackgroundColor',AColorMap.Color);
      SetRttiPropertyValue(AComponent,'GutterColor',AColorMap.Color);
      SetRttiPropertyValue(AComponent,'HighlightFontColor',AColorMap.FontColor);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
    end
    else
    if AComponent.ClassName='TRefactoringTree' then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
    end
    else
    if AComponent.ClassName='TStringGrid' then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'FixedColor',AColorMap.Color);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
    end
    else
    if AComponent.ClassName='TBetterHintWindowVirtualDrawTree' then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);

       {$IF CompilerVersion >= 23}
        if GlobalSettings.UseVCLStyles then
        begin
        //  if not IsStyleHookRegistered(AComponent.ClassType, TTreeViewStyleHook) then
        //   TStyleEngine.RegisterStyleHook(AComponent.ClassType, TTreeViewStyleHook);
        end;
       {$IFEND}
    end
    else
    if AComponent.ClassName='TVirtualStringTree' then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
      //SetRttiPropertyValue(AComponent,'TreeLineColor',AColorMap.FontColor);
        //  TVTColors
        //	__fastcall TVTColors(TBaseVirtualTree* AOwner);
        //	virtual void __fastcall Assign(Classes::TPersistent* Source);
        //
        //__published:
        //	__property Graphics::TColor BorderColor = {read=GetColor, write=SetColor, index=7, default=-16777201};
        //	__property Graphics::TColor DisabledColor = {read=GetColor, write=SetColor, index=0, default=-16777200};
        //	__property Graphics::TColor DropMarkColor = {read=GetColor, write=SetColor, index=1, default=-16777203};
        //	__property Graphics::TColor DropTargetColor = {read=GetColor, write=SetColor, index=2, default=-16777203};
        //	__property Graphics::TColor DropTargetBorderColor = {read=GetColor, write=SetColor, index=11, default=-16777203};
        //	__property Graphics::TColor FocusedSelectionColor = {read=GetColor, write=SetColor, index=3, default=-16777203};
        //	__property Graphics::TColor FocusedSelectionBorderColor = {read=GetColor, write=SetColor, index=9, default=-16777203};
        //	__property Graphics::TColor GridLineColor = {read=GetColor, write=SetColor, index=4, default=-16777201};
        //	__property Graphics::TColor HeaderHotColor = {read=GetColor, write=SetColor, index=14, default=-16777200};
        //	__property Graphics::TColor HotColor = {read=GetColor, write=SetColor, index=8, default=-16777208};
        //	__property Graphics::TColor SelectionRectangleBlendColor = {read=GetColor, write=SetColor, index=12, default=-16777203};
        //	__property Graphics::TColor SelectionRectangleBorderColor = {read=GetColor, write=SetColor, index=13, default=-16777203};
        //	__property Graphics::TColor TreeLineColor = {read=GetColor, write=SetColor, index=5, default=-16777200};
        //	__property Graphics::TColor UnfocusedSelectionColor = {read=GetColor, write=SetColor, index=6, default=-16777201};
        //	__property Graphics::TColor UnfocusedSelectionBorderColor = {read=GetColor, write=SetColor, index=10, default=-16777201};
       {$IF CompilerVersion >= 23}
        if GlobalSettings.UseVCLStyles then
        begin
          if not IsStyleHookRegistered(AComponent.ClassType, TTreeViewStyleHook) then
           TStyleEngine.RegisterStyleHook(AComponent.ClassType, TTreeViewStyleHook);
        end;
       {$IFEND}
    end
    else
    if AComponent.ClassName='TCodeEditorTabControl' then
    begin
      SetRttiPropertyValue(AComponent,'UnselectedColor',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'SelectedColor',AColorMap.Color);
      SetRttiPropertyValue(AComponent,'BackgroundColor',AColorMap.MenuColor);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
    end
    else
    if AComponent.ClassName='TEditorDockPanel' then
    begin
      SetRttiPropertyValue(AComponent,'Color',AColorMap.Color);
      SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);
    end
    else
    if AComponent.ClassName='TScrollerButton' then
    begin

    end
    else
    if AComponent.ClassName='TClosableTabScroller' then //experimental
    begin

       {$IF CompilerVersion >= 23}
       {
        if GlobalSettings.UseVCLStyles then
        begin
          if not IsStyleHookRegistered(AComponent.ClassType, TTabControlStyleHook) then
           TStyleEngine.RegisterStyleHook(AComponent.ClassType, TTabControlStyleHook);
        end;
       }
       {$IFEND}

        {
          p := ctx.GetType(AComponent.ClassInfo).GetProperty('Handle');
          if p<>nil then
          SetWindowTheme(p.GetValue(AComponent).AsInteger,'','');
        }
        {$IF CompilerVersion > 20}
        f := ctx.GetType(AComponent.ClassInfo).GetField('FColor');
        if f<>nil then
          f.SetValue(AComponent,AColorMap.MenuColor);
              {
        m:=ctx.GetType(AComponent.ClassInfo).GetMethod('Update');
        m.Invoke(p.GetValue(AComponent).AsObject,[]);
              }
       {$IFEND}

       SetRttiPropertyValue(AComponent,'LeftButton.BackgroundColor',AColorMap.Color);
       SetRttiPropertyValue(AComponent,'LeftButton.Transparent',False);
       SetRttiPropertyValue(AComponent,'LeftButton.Flat',True);

                   {
             BackgroundColor
             RightButton
                   }
    end
    else
    if AComponent.ClassName='TTabScroller' then
    begin

    end
    else
    if AComponent.ClassName='TEditControl' then   //TODO
    begin
       {$IF CompilerVersion >= 23}
        if GlobalSettings.UseVCLStyles then
        begin
          if not IsStyleHookRegistered(AComponent.ClassType, TMemoStyleHook) then
           TStyleEngine.RegisterStyleHook(AComponent.ClassType, TMemoStyleHook);
        end;
       {$IFEND}
        {
        l2 := TStringList.Create;
        try
         l2.Text:=DumpTypeDefinition(AComponent.ClassInfo);
        finally
         l2.SaveToFile('C:\Users\Public\Documents\RAD Studio\Projects\2010\pkgDelphiWithTheme\TEditControl.txt');
         l2.Free;
        end;
        }
        {
          p := ctx.GetType(AComponent.ClassInfo).GetProperty('Handle');
          if p<>nil then
          SetWindowTheme(p.GetValue(AComponent).AsInteger,'','');
        }
(*
        f := ctx.GetType(AComponent.ClassInfo).GetField('CurBackColor');
        if f<>nil then
        begin
          f.SetValue(AComponent,AColorMap.Color);
          {$IFDEF DEBUG_PROFILER}
           lprofiler.Add('********CurBackColor******');
          {$ENDIF}

        end;
*)
         {
         f := ctx.GetType(AComponent.ClassInfo).GetField('GutterBrush');
         p2 := ctx.GetType(f.FieldType.Handle).GetProperty('Color');
         }
{
   CurForeColor        :TColor;
   CurBackColor        :TColor;

}

         //showMessage('ColorMap '+IntToStr(AColorMap.Color));
         //showMessage('Before '+p2.GetValue(f.GetValue(AComponent).AsObject).ToString());
         //p2.SetValue(f.GetValue(AComponent).AsObject,AColorMap.Color);
         //showMessage('After '+p2.GetValue(f.GetValue(AComponent).AsObject).ToString());
    end
    else
    if AComponent is TActionToolBar then
    with TActionToolBar(AComponent) do
    begin
      ColorMap:=AColorMap;
    end
    else
    if AComponent is TControlBar then
    with TControlBar(AComponent) do
    begin
      Color := AColorMap.Color;//$00F1E9E0;
      {.$IF COMPILERVERSION > 21}
      DrawingStyle := dsGradient;
      GradientStartColor :=  AColorMap.Color;//$00D1B499
      GradientEndColor   :=  AColorMap.Color;//$00D1B499
      {.$IFEND};
    end
    else
    if AComponent.ClassName = 'TDockToolBar' then
    begin
      //DumpComponent(AComponent);
      with TToolBar(AComponent) do
      begin
        Color              := AColorMap.Color;
        {.$IF COMPILERVERSION > 21}
        DrawingStyle       := TTBDrawingStyle(dsGradient);
        GradientStartColor := AColorMap.MenuColor;
        GradientEndColor   := AColorMap.Color;//$00D1B499;
        {.$IFEND}
        HotTrackColor      := AColorMap.SelectedColor;
        Font.Color         := AColorMap.FontColor;
      end;
    end
    else
    if AComponent is TActionMainMenuBar then
    with TActionMainMenuBar(AComponent) do
    begin
      AnimationStyle  := asFade;
      AnimateDuration := 1200;
      Shadows         := True;
      ColorMap        := AColorMap;
      Font.Color      := AColorMap.FontColor;
    end
    else
    if AComponent is TActionManager then
    with TActionManager(AComponent) do
    begin
      Style := XPStyle;
    end
    else
    if AComponent.ClassName = 'TTabSet' then
    with TTabSet(AComponent) do
    begin
      BackgroundColor:=AColorMap.MenuColor;
      SelectedColor  :=AColorMap.Color;
      UnselectedColor:=AColorMap.MenuColor;
      Font.Color    := AColorMap.FontColor;
    end
    else
    if (AComponent.ClassName = 'TIDEGradientTabSet') or (AComponent.ClassName = 'TGradientTabSet') then
    begin
         {
         f := ctx.GetType(AComponent.ClassInfo).GetField('FColor');
         f.SetValue(AComponent,AColorMap.Color);

         p := ctx.GetType(AComponent.ClassInfo).GetProperty('ParentBackground');
         p.SetValue(AComponent,false);

         p := ctx.GetType(AComponent.ClassInfo).GetProperty('Brush');
         p2 := ctx.GetType(p.PropertyType.Handle).GetProperty('Color');
         p2.SetValue(p.GetValue(AComponent).AsObject,AColorMap.Color);
         }

         SetRttiPropertyValue(AComponent,'TabColors.ActiveStart',AColorMap.Color);
         SetRttiPropertyValue(AComponent,'TabColors.ActiveEnd',AColorMap.Color);
         SetRttiPropertyValue(AComponent,'TabColors.InActiveStart',AColorMap.MenuColor);
         SetRttiPropertyValue(AComponent,'TabColors.InActiveEnd',AColorMap.MenuColor);
         SetRttiPropertyValue(AComponent,'Font.Color',AColorMap.FontColor);

       {$IF CompilerVersion >= 23}
        {
        if GlobalSettings.UseVCLStyles then
        begin
          if not IsStyleHookRegistered(AComponent.ClassType, TTabControlStyleHook) then
           TStyleEngine.RegisterStyleHook(AComponent.ClassType, TTabControlStyleHook);
        end;
        }
       {$IFEND}

    end
    else
    if AComponent.ClassName='TTabSheet'  then
    with TTabSheet(AComponent) do
    begin
       //Color:=AColorMap.Color;
       Font.Color:=AColorMap.FontColor;
    end
    else
    if AComponent is TStatusBar then
    with TStatusBar(AComponent) do
    begin
       //SetWindowTheme(TStatusBar(AComponent).Handle,'','');
       Color := AColorMap.Color;
       for i := 0 to TStatusBar(AComponent).Panels.Count-1 do
        TStatusBar(AComponent).Panels[i].Bevel:=pbNone;

       Font.Color:=AColorMap.FontColor;
    end
    else
    if AComponent is TFrame then
    with TFrame(AComponent) do
    begin
      Color := AColorMap.Color;
      Font.Color:=AColorMap.FontColor;
    end
    else
    begin
      {$IFDEF DEBUG_PROFILER}
        lpignored.Add(Format('%s component %s:%s',[formatdatetime('hh:nn:ss.zzz',Now) ,AComponent.Name,AComponent.ClassName]));
      {$ENDIF}
    end;

    {$IFDEF DEBUG_PROFILER}
      lprofiler.Add(Format('%s End process component %s:%s',[formatdatetime('hh:nn:ss.zzz',Now) ,AComponent.Name,AComponent.ClassName]));
    {$ENDIF}

    for I := 0 to AComponent.ComponentCount - 1 do
    begin
     {$IFDEF DEBUG_MODE}
     //lcomp.Add(Format('     %s : %s',[AComponent.Components[I].Name,AComponent.Components[I].ClassName]));
     {$ENDIF}
     ProcessComponent(AColorMap, AComponent.Components[I]);
    end;
end;

initialization
  GlobalColorMap:=nil;
  GlobalSettings:=nil;
  HookedWindows:=TStringList.Create;
  //ShowMessage(ParamStr(0));
  //ShowMessage(GetBplLocation);
  HookedWindows.LoadFromFile(IncludeTrailingPathDelimiter(ExtractFilePath(GetBplLocation))+'HookedWindows.dat');
{$IF CompilerVersion > 20}
  ctx:=TRttiContext.Create;
{$IFEND}

{$IFDEF DEBUG_PROFILER}
  ShowMessage('warning DEBUG_PROFILER mode Activated');
  lprofiler:=TStringList.Create;
  lpignored:=TStringList.Create;
  lDumped  :=TStringList.Create;
{$ENDIF}

finalization
  HookedWindows.Free;
  HookedWindows:=nil;
{$IF CompilerVersion > 20}
  ctx.Free;
{$IFEND}

{$IFDEF DEBUG_PROFILER}
  lprofiler.SaveToFile(ExtractFilePath(GetBplLocation())+'Profiler\profiler.txt');
  lprofiler.Free;
  lpignored.SaveToFile(ExtractFilePath(GetBplLocation())+'Profiler\ignored.txt');
  lpignored.Free;
  lDumped.Free;
{$ENDIF}


end.