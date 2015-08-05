﻿//=============================================================================
//             ╔═══════════╦═╗
//             ║           ║ ║
//             ║           ║ ║
//             ║ ╔╗ ║║ ╔╗ ╔╣ ║
//             ║ ╚╣ ╚╝ ╚╩ ╚╝ ║
//             ║  ║ engine   ║
//             ║  ║          ║
//             ╚══╩══════════╝
//
// For license see COPYING
//=============================================================================

unit QuadEngine.Camera;

interface

Uses
  QuadEngine, QuadEngine.Render, Winapi.DXTypes, Math, Vec2f;

type
  TQuadCamera = class(TInterfacedObject, IQuadCamera)
  private
    FRender: TQuadRender;
    FViewMatrix: D3DMATRIX;
    FAngle: Single;
    FScale: Single;
    FTranslation: TVec2f;
  public
    constructor Create(AQuadRender: TQuadRender);
    procedure Scale(AScale: Single); stdcall;
    procedure Rotate(AAngle: Single); stdcall;
    procedure Translate(const ADistance: TVec2f); stdcall;
    procedure Reset; stdcall;
    procedure Enable; stdcall;
    procedure Disable; stdcall;
    function GetPosition: TVec2f; stdcall;
    function GetAngle: Single; stdcall;
    function GetScale: Single; stdcall;
    procedure SetAngle(AAngle: Single); stdcall;
    procedure SetPosition(APosition: TVec2f); stdcall;
  end;

function MultiplyMatrix(const A, B: D3DMATRIX): D3DMATRIX; inline;

implementation

uses
  QuadEngine.Device, Winapi.Direct3D9;

{ TQuadCamera }

function MultiplyMatrix(const A, B: D3DMATRIX): D3DMATRIX;
var
  i, j: Integer;
  r: Integer;
begin
  for i := 0 to 3 do
  for j := 0 to 3 do
  begin
    Result.m[i, j] := 0;
    for r := 0 to 3 do
      Result.m[i, j] := Result.m[i, j] + A.m[i, r] * B.m[r, j];
  end;
end;

procedure TQuadCamera.Enable;
var
  SinA, CosA: Single;
  RotateMatrix: D3DMATRIX;
  TranslateMatrix: D3DMATRIX;
  ScaleMatrix: D3DMATRIX;
begin
  FRender.FlushBuffer;

  SinCos(DegToRad(FAngle), SinA, CosA);

  // TranslateMatrix
  TranslateMatrix._11 := 1;
  TranslateMatrix._12 := 0;
  TranslateMatrix._13 := 0;
  TranslateMatrix._14 := 0;

  TranslateMatrix._21 := 0;
  TranslateMatrix._22 := 1;
  TranslateMatrix._23 := 0;
  TranslateMatrix._24 := 0;

  TranslateMatrix._31 := 0;
  TranslateMatrix._32 := 0;
  TranslateMatrix._33 := 1;
  TranslateMatrix._34 := 0;

  TranslateMatrix._41 := -(FRender.Width / 2) - FTranslation.X;
  TranslateMatrix._42 := -(FRender.Height / 2) - FTranslation.Y;
  TranslateMatrix._43 := 0;
  TranslateMatrix._44 := 1;


  // RotateMatrix
  RotateMatrix._11 := 2 / FRender.Width * CosA;
  RotateMatrix._12 := - 2 / FRender.Height * SinA;
  RotateMatrix._13 := 0;
  RotateMatrix._14 := 0;

  RotateMatrix._21 := 2 / FRender.Width * (- SinA);
  RotateMatrix._22 := -2 / FRender.Height * CosA;
  RotateMatrix._23 := 0;
  RotateMatrix._24 := 0;

  RotateMatrix._31 := 0;
  RotateMatrix._32 := 0;
  RotateMatrix._33 := 1;
  RotateMatrix._34 := 0;

  RotateMatrix._41 := 0;
  RotateMatrix._42 := 0;
  RotateMatrix._43 := 0;
  RotateMatrix._44 := 1;

  // ScaleMatrix
  ScaleMatrix._11 := FScale;
  ScaleMatrix._12 := 0;
  ScaleMatrix._13 := 0;
  ScaleMatrix._14 := 0;

  ScaleMatrix._21 := 0;
  ScaleMatrix._22 := FScale;
  ScaleMatrix._23 := 0;
  ScaleMatrix._24 := 0;

  ScaleMatrix._31 := 0;
  ScaleMatrix._32 := 0;
  ScaleMatrix._33 := 1;
  ScaleMatrix._34 := 0;

  ScaleMatrix._41 := 0;
  ScaleMatrix._42 := 0;
  ScaleMatrix._43 := 0;
  ScaleMatrix._44 := 1;

  FViewMatrix := MultiplyMatrix(MultiplyMatrix(TranslateMatrix, RotateMatrix), ScaleMatrix);

  Device.LastResultCode := FRender.D3DDevice.SetTransform(D3DTS_PROJECTION, FViewMatrix);
  FRender.ViewMatrix := FViewMatrix;
end;

constructor TQuadCamera.Create(AQuadRender: TQuadRender);
begin
  FRender := AQuadRender;
  FScale := 1.0;
  FAngle := 0;
end;

procedure TQuadCamera.Reset;
begin
  FRender.FlushBuffer;

  FViewMatrix._11 := 2 / FRender.Width;
  FViewMatrix._12 := 0;
  FViewMatrix._13 := 0;
  FViewMatrix._14 := 0;

  FViewMatrix._21 := 0;
  FViewMatrix._22 := -2 / FRender.Height;
  FViewMatrix._23 := 0;
  FViewMatrix._24 := 0;

  FViewMatrix._31 := 0;
  FViewMatrix._32 := 0;
  FViewMatrix._33 := 1;
  FViewMatrix._34 := 0;

  FViewMatrix._41 := -1;
  FViewMatrix._42 := 1;
  FViewMatrix._43 := 0;
  FViewMatrix._44 := 1;

  FTranslation := TVec2f.Zero;
  FAngle := 0;
  FScale := 1.0;

  Device.LastResultCode := FRender.D3DDevice.SetTransform(D3DTS_PROJECTION, FViewMatrix);
end;

procedure TQuadCamera.Rotate(AAngle: Single);
begin
  FAngle := FAngle + AAngle;
end;

procedure TQuadCamera.Translate(const ADistance: TVec2f);
begin
  FTranslation := FTranslation + ADistance;
end;

procedure TQuadCamera.Scale(AScale: Single);
begin
  FScale := AScale;
end;

procedure TQuadCamera.Disable;
begin
  FRender.ChangeResolution(FRender.Width, FRender.Height);
end;

function TQuadCamera.GetPosition: TVec2f;
begin
  Result := FTranslation;
end;

function TQuadCamera.GetAngle: Single;
begin
  Result := FAngle;
end;

function TQuadCamera.GetScale: Single;
begin
  Result := FScale;
end;

procedure TQuadCamera.SetAngle(AAngle: Single);
begin
  FAngle := AAngle;
end;

procedure TQuadCamera.SetPosition(APosition: TVec2f);
begin
  FTranslation := APosition;
end;


end.
