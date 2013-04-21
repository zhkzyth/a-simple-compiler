
{--------------------------------------------------------------}
program Cradle;

{--------------------------------------------------------------}
{ Constant Declarations }

const TAB = ^I;
   CR     = ^M;

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
{ Recognize and Translate an Expression }
{ This version is a dummy }

procedure Expression;
begin
   EmitLn('<expr>');
end;

{--------------------------------------------------------------}
{ Recognize and Translate an IF Construct }

procedure Block(L :string );Forward;

procedure DoIf(L :string );
var L1,L2 : string;
begin
   Match('i');
   Condition;
   L1 := NewLabel;
   L2 := L1;
   EmitLn('BEQ ' + L1);
   Block(L);
   if Look = 'l' then begin
      Match('l');
      L2 := NewLabel;
      EmitLn('BRA ' + L2);
      PostLabel(L1);
      Block(L);
   end;
   Match('e');
   PostLabel(L2);
end;

{--------------------------------------------------------------}
{ Recognize and Translate a While Statement }

procedure DoWhile;
var L1,L2 : string;
begin
   Match('w');
   L1 := NewLabel;
   L2 := NewLabel;
   PostLabel(L1);
   Condition;
   EmitLn('BEQ '+ L2);
   Block(L2);
   Match('e');
   EmitLn('BRA '+ L1);
   PostLabel(L2);
end;


{--------------------------------------------------------------}
{ Recognize and Translate a LOOP Statement }

procedure DoLoop;
var L1,L2 : string;
begin
   Match('p');
   L1 := NewLabel;
   L2 := NewLabel;
   PostLabel(L1);
   Block(L2);
   Match('e');
   EmitLn('BRA ' + L1);
   PostLabel(L2);
end;


{--------------------------------------------------------------}
{ Recognize and Translate a REPEAT Statement }

procedure DoRepeat;
var L1,L2 : string;
begin
   Match('r');
   L1 := NewLabel;
   L2 := NewLabel;
   PostLabel(L1);
   Block(L2);
   Match('u');
   Condition;
   EmitLn('BEQ ' + L1);
   PostLabel(L2);
end;


{--------------------------------------------------------------}
{ Recognize and Translate a DO Statement }

procedure DoDo;
var L1,L2 : string;
begin
   Match('d');
   L1 := NewLabel;
   L2 := NewLabel;
   Expression;
   EmitLn('SUBQ #1,D0');
   PostLabel(L1);
   EmitLn('MOVE D0,-(SP)');
   Block(L2);
   EmitLn('MOVE +(SP),D0');   { save the limit in stack}
   EmitLn('DBRA D0,' + L1);
   EmitLn('SUBQ #2,SP');
   PostLabel(L2);
   EmitLn('ADDQ #2,SP') {clear the statck after we break out}
end;


{--------------------------------------------------------------}
{ Recognize and Translate a FOR Statement }

procedure DoFor;
var L1,L2 : string;
   Name   : char;
begin
   Match('f');
   L1 := NewLabel;
   L2 := NewLabel;
   { Step1: init loop counter value }
   Name := GetName;
   Match('=');
   Expression;
   EmitLn('SUBQ #1,D0');
   EmitLn('LEA ' + Name + '(PC),A0');
   EmitLn('MOVE D0,(A0)');
   { Step2: set limit value }
   Expression;
   EmitLn('MOVE D0,-(SP)');   { save the limit in stack}

   PostLabel(L1);
   { the for loop}
   { be cautious about the loop counter }
   EmitLn('LEA ' + Name + '(PC),A0');
   EmitLn('MOVE (A0),D0');
   EmitLn('ADDQ #1,D0');
   EmitLn('CMP (SP),D0');
   EmitLn('BGT ' + L2); {BRANCH ON GREATER THAN}
   Block(L2);
   Match('e');
   EmitLn('BRA ' + L1);
   PostLabel(L2);
   EmitLn('ADDQ #2,SP');
end;

{--------------------------------------------------------------}
{ Recognize and Translate a BREAK }

procedure DoBreak(L :string );
begin
   Match('b');
   if L <> '' then
      EmitLn('BRA ' + L )
   else Abort('No loop to break from');
end;


{--------------------------------------------------------------}
{ Recognize and Translate a Statement Block }

procedure Block(L :string );
begin
   while not( Look in ['e','l','u']) do begin
      case Look of
        'i' : DoIf(L);
        'w' : DoWhile;
        'p' : DoLoop;
        'r' : DoRepeat;
        'f' : DoFor;
        'd' : DoDo;
        'b' : DoBreak(L);
        else Other;
      end;
   end;
end;


{--------------------------------------------------------------}
{ Parse and Translate a Program }

procedure DoProgram;
begin
   Block('');
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
