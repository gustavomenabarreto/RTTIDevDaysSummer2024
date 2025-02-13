unit RttiExemplos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TMyClass = class
  private
    FValue: Integer;
  public
    property MyProperty: Integer read FValue write FValue;
  end;

  TPerson = class
  private
    FName: string;
    FLastName: string;
  public
    property Name: string read FName write FName;
    property LastName: string read FLastName write FLastName;
  end;

  TComponentInfo = class
  public
    ComponentClass: TComponentClass;
    PropertyName: string;
    Caption: string;
  end;

  TFormStructure = class
  public
    ButtonInfo: TComponentInfo;
    LabelInfo: TComponentInfo;
  end;

  ComponentClassAttribute = class(TCustomAttribute)
  private
    FComponentClass: TComponentClass;
    FName: string;
    FCaption: string;
  public
    constructor Create(AComponentClass: TComponentClass;AName,ACaption: string);
    property ComponentClass: TComponentClass read FComponentClass;
    property Name: string read FName;
    property Caption: string read FCaption;
  end;

  TFormDefault = class
  private
    FButtonInfo: TComponentInfo;
    FLabelInfo: TComponentInfo;
  public
    [ComponentClass(TButton,'Button1','Click Here')]
    property ButtonInfo: TComponentInfo read FButtonInfo write FButtonInfo;
    [ComponentClass(TLabel, 'Label1', 'My Label')]
    property LabelInfo: TComponentInfo read FLabelInfo write FLabelInfo;
  end;

  TFormRTII = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function CreateWriteForm(const FormStructure: TFormStructure): TForm;
    function SerializeObject(obj: TObject): string;
    function DeserializeObject(jsonData: string; objClass: TClass): TObject;
  end;

var
  FormRTII: TFormRTII;

implementation

uses
  RTTI, JSON;

{$R *.dfm}

procedure TFormRTII.Button1Click(Sender: TObject);
begin
	if (Sender is TButton) then
	begin
		(Sender as TButton).Caption := 'RTTI Conference';
	end;
end;

procedure TFormRTII.Button2Click(Sender: TObject);
var
   i: Integer;
begin
  for i := 0 to ComponentCount -1 do
  begin
    if (Components[i] is TEdit) then
      (Components[i] as TEdit).Clear;
  end;
end;

procedure TFormRTII.Button3Click(Sender: TObject);
var
  MyObj: TMyClass;
  Ctx: TRttiContext;
  MyProp: TRttiProperty;
begin
  MyObj := TMyClass.Create;
  try
    MyObj.MyProperty := 2024;

    Ctx := TRttiContext.Create;
    try
      MyProp := Ctx.GetType(TMyClass).GetProperty('MyProperty');
      if Assigned(MyProp) then
      begin
        ShowMessage('Property Name: ' + MyProp.Name);
        ShowMessage('Property Value: ' + MyProp.GetValue(MyObj).ToString);
      end;
    finally
      Ctx.Free;
    end;
  finally
    MyObj.Free;
  end;
end;

procedure TFormRTII.Button4Click(Sender: TObject);
var
  Person: TPerson;
  serializedData: string;
  deserializedPerson: TPerson;
begin
  Person := TPerson.Create;
  Person.Name := 'Gustavo';
  Person.LastName := 'Mena Barreto';

  serializedData := SerializeObject(Person);

  deserializedPerson :=
    DeserializeObject(serializedData, TPerson) as TPerson;

  ShowMessage(deserializedPerson.Name);
  ShowMessage(deserializedPerson.LastName);
end;

procedure TFormRTII.Button5Click(Sender: TObject);
var
  MyFormStructure: TFormStructure;
  MyForm: TForm;
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
  Attr: TCustomAttribute;
begin
  MyFormStructure := TFormStructure.Create;
  RttiContext := TRttiContext.Create;
  try
    RttiType := RttiContext.GetType(TFormDefault);
    for Prop in RttiType.GetProperties do
    begin
      for Attr in Prop.GetAttributes do
      begin
        if Attr is ComponentClassAttribute then
        begin
          if ComponentClassAttribute(Attr).ComponentClass = TButton then
          begin
            MyFormStructure.ButtonInfo := TComponentInfo.Create;
            MyFormStructure.ButtonInfo.ComponentClass := ComponentClassAttribute(Attr).ComponentClass;
            MyFormStructure.ButtonInfo.PropertyName := ComponentClassAttribute(Attr).Name;
            MyFormStructure.ButtonInfo.Caption := ComponentClassAttribute(Attr).Caption;
          end;

          if ComponentClassAttribute(Attr).ComponentClass = TLabel then
          begin
            MyFormStructure.LabelInfo := TComponentInfo.Create;
            MyFormStructure.LabelInfo.ComponentClass := ComponentClassAttribute(Attr).ComponentClass;
            MyFormStructure.LabelInfo.PropertyName := ComponentClassAttribute(Attr).Name;
            MyFormStructure.LabelInfo.Caption := ComponentClassAttribute(Attr).Caption;
          end;
        end;
      end;
    end;
   MyForm := CreateWriteForm(MyFormStructure);
   MyForm.Show;
  finally
    RttiContext.Free;
  end;
end;

function TFormRTII.CreateWriteForm(const FormStructure: TFormStructure): TForm;
var
  Form: TForm;
  Button: TButton;
  LabelCtrl: TLabel;
  Ctx: TRttiContext;
  Tp: TRttiType;
  rttMeuField: TRttiField;
begin
  Form := TForm.Create(nil);
  Form.Caption := 'Dynamic Form';
  Form.Width := 400;
  Form.Height := 200;
  Form.Position := poDesktopCenter;

  Ctx := TRttiContext.Create;
  Tp := Ctx.GetType(FormStructure.ClassType);
  try
    rttMeuField := Tp.GetField('ButtonInfo');
    if Assigned(rttMeuField)  then
    begin
      Button := TButton.Create(Form);
      Button.Left:= 2;
      Button.Parent := Form;
      Button.Caption := FormStructure.ButtonInfo.Caption;
    end;

    rttMeuField := Tp.GetField('LabelInfo');
    if Assigned(rttMeuField)  then
    begin
      LabelCtrl := TLabel.Create(Form);
      LabelCtrl.Left := 100;
      LabelCtrl.Parent := Form;
      LabelCtrl.Caption := FormStructure.LabelInfo.Caption;
    end;
  finally
    Ctx.Free;
  end;
  Result := Form;
end;

function TFormRTII.SerializeObject(obj: TObject): string;
var
  ctx: TRttiContext;
  prop: TRttiProperty;
  jsonObject: TJSONObject;
begin
  ctx := TRttiContext.Create;
  try
    jsonObject := TJSONObject.Create;

    for prop in ctx.GetType(obj.ClassType).GetProperties do
    begin
      jsonObject.AddPair(prop.Name, prop.GetValue(obj).ToString);
    end;

    Result := jsonObject.ToJSON;
  finally
    ctx.Free;
  end;
end;

function TFormRTII.DeserializeObject(jsonData: string;
  objClass: TClass): TObject;
var
  ctx: TRttiContext;
  prop: TRttiProperty;
  jsonObject: TJSONObject;
  obj: TObject;
  Nome: string;
begin
  ctx := TRttiContext.Create;
  try
    jsonObject := TJSONObject.ParseJSONValue(jsonData) as TJSONObject;
    obj := objClass.Create;

    for prop in ctx.GetType(obj.ClassType).GetProperties do
    begin
      if jsonObject.TryGetValue<string>(prop.Name, Nome) then
      begin
        prop.SetValue(obj, TValue(Nome));
      end;
    end;

    Result := obj;
  finally
    ctx.Free;
  end;
end;

constructor ComponentClassAttribute.Create(AComponentClass: TComponentClass; AName, ACaption: string);
begin
  FComponentClass := AComponentClass;
  FName := AName;
  FCaption := ACaption;
end;

end.
