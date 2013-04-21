
{--------------------------------------------------------------}
program Cradle;

{--------------------------------------------------------------}
{ Constant Declarations }

const TAB = ^I;

{--------------------------------------------------------------}
{ Variable Declarations }

var Look  : char;              { Lookahead Character }
   LCount : integer;

{--------------------------------------------------------------}
{ Read New Character From Input Stream }

procedure GetChar;
begin
   Read(Look);
end;

{--------------------------------------------------------------}
{ Report an Error }

procedure Error(s: string);
begin
   WriteLn;
   WriteLn(^G, 'Error: ', s, '.');
end;


{--------------------------------------------------------------}
{ Report Error and Halt }

procedure Abort(s: string);
begin
   Error(s);
   Halt;
end;


{--------------------------------------------------------------}
{ Report What Was Expected }

procedure Expected(s: string);
begin
   Abort(s + ' Expected');
end;

{--------------------------------------------------------------}
{ Match a Specific Input Character }

procedure Match(x: char);
begin
   if Look = x then GetChar
   else Expected('''' + x + '''');
end;


{--------------------------------------------------------------}
{ Recognize an Alpha Character }

function IsAlpha(c: char): boolean;
begin
   IsAlpha := upcase(c) in ['A'..'Z'];
end;


{--------------------------------------------------------------}

{ Recognize a Decimal Digit }

function IsDigit(c: char): boolean;
begin
   IsDigit := c in ['0'..'9'];
end;


{--------------------------------------------------------------}
{ Get an Identifier }

function GetName: char;
begin
   if not IsAlpha(Look) then Expected('Name');
   GetName := UpCase(Look);
   GetChar;
end;


{--------------------------------------------------------------}
{ Get a Number }

function GetNum: char;
begin
   if not IsDigit(Look) then Expected('Integer');
   GetNum := Look;
   GetChar;
end;


{--------------------------------------------------------------}
{ Output a String with Tab }

procedure Emit(s: string);
begin
   Write(TAB, s);
end;




{--------------------------------------------------------------}
{ Output a String with Tab and CRLF }

procedure EmitLn(s: string);
begin
   Emit(s);
   WriteLn;
end;

{--------------------------------------------------------------}
{ Initialize }

procedure Init;
begin
   LCount := 0;
   GetChar;
end;


{--------------------------------------------------------------}
{ Recognize and Translate an "Other" }

procedure Other;
begin
   EmitLn(GetName);
end;

{--------------------------------------------------------------}
{ Generate a Unique Label }

function NewLabel:string;
var S : string;
begin
   Str(LCount,S);
   NewLabel:='L'+S;
   Inc(LCount);
end;

{--------------------------------------------------------------}
{ Post a Label To Output}

procedure PostLabel(L :string );
begin
   WriteLn(L, ':');
end;

{--------------------------------------------------------------}
{ Recognize and Translate an Boolean Condition }
{ This version is a dummy }

procedure Condition;
begin
   EmitLn('<condition>');
end;

{--------------------------------------------------------------}
{ Recognize and Translate an IF Construct }

procedure Block;Forward;

procedure DoIf;
var L1,L2 : string;
begin
   Match('i');
   Condition;
   L1 := NewLabel;
   L2 := L1;
   EmitLn('BEQ ' + L1);
   Block;
   if Look = 'l' then begin
      Match('l');
      L2 := NewLabel;
      EmitLn('BRA ' + L2);
      PostLabel(L1);
      Block;
   end;
   Match('e');
   PostLabel(L2);
end;

{--------------------------------------------------------------}
{ Recognize and Translate a While Block }

procedure DoWhile;
var L1,L2 : string;
begin
   Match('w');
   L1 := NewLabel;
   L2 := NewLabel;
   PostLabel(L1);
   Condition;
   EmitLn('BEQ '+ L2);
   Block;
   Match('e');
   EmitLn('BRA '+ L1);
   PostLabel(L2);
end;


{--------------------------------------------------------------}
{ Recognize and Translate a LOOP Block }

procedure DoLoop;
var L : string;
begin
   Match('p');
   L := NewLabel;
   PostLabel(L);
   Block;
   Match('e');
   EmitLn('BRA ' + L);
end;


{--------------------------------------------------------------}
{ Recognize and Translate a Statement Block }

procedure Block;
begin
   while not( Look in ['e','l']) do begin
      case Look of
        'i' : DoIf;
        'w' : DoWhile;
        'p' : DoLoop;
        else Other;
      end;
   end;
end;


{--------------------------------------------------------------}
{ Parse and Translate a Program }

procedure DoProgram;
begin
   Block;
   if Look <> 'e' then Expected('END');
   EmitLn('END')
end;



{--------------------------------------------------------------}
{ Main Program }

begin
   Init;
   { Other; }
   DoProgram;
end.
{--------------------------------------------------------------}
