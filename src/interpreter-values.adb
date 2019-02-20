with Ada.Strings;
with Ada.Strings.Wide_Wide_Unbounded.Wide_Wide_Text_IO; 
use Ada.Strings.Wide_Wide_Unbounded.Wide_Wide_Text_IO;
with Ada.Float_Text_IO;
with Ada.Strings.UTF_Encoding.Wide_Wide_Strings; 
use Ada.Strings.UTF_Encoding.Wide_Wide_Strings;
with Langkit_Support.Text; use Langkit_Support.Text;

package body Interpreter.Values is
   function To_String (Kind: Value_Kind) return String is
   begin
      case Kind is
         when Unit => return "";
         when Number => return "Number";
         when Int => return "Int";
         when Str => return "Str";
      end case;
   end To_String;
   
   
   procedure Display (Value: in ExprVal) is
   begin
      Put_Line (To_String (Value));
   end Display;
   
   function Format_Float(N: in Float) return Text_Type is
      Integral: Integer := Integer (N);
      Integral_Str: Text_Type := Integer'Wide_Wide_Image (Integral);
      Decimal: Float := N - Float (Integral);
      Decimal_Int: Integer := Integer (Decimal * (Float (10 ** Float'Exponent (Decimal))));
      Decimal_Str: Text_Type := Integer'Wide_Wide_Image (Decimal_Int);
      Repr: Text_Type := 
        Integral_Str (Integral_Str'First + 1 .. Integral_Str'Last) & "." 
        & Decimal_Str (Decimal_Str'First + 1 .. Decimal_Str'Last);
   begin
      return (if N > 0.0001 and then N < 9_999_999_999.0 then Repr
             else Float'Wide_Wide_Image (N));
   end;
   
   function To_String (Value: in ExprVal) return Unbounded_Text_Type is
   begin
      case Value.Kind is
         when Unit => 
            return To_Unbounded_Text ("()");
         when Number => 
            return To_Unbounded_Text (Format_Float (Value.Number_Val));
         when Int =>
            return To_Unbounded_Text (Integer'Wide_Wide_Image (Value.Int_Val));
         when Str =>
            return Value.Str_Val;
      end case;
   end To_String;
   
   
   function "+" (Left, Right: ExprVal) return ExprVal is
   begin
      case Left.Kind is
         when Unit => raise Unsupported with "Wrong left operand for '+': ()";
         when Number => return Left.Number_Val + Right;
         when Int => return Left.Int_Val + Right;
         when Str => return Left.Str_Val + Right;
      end case;
   end "+";
   
   function "+" (Left: Float; Right: ExprVal) return ExprVal is
   begin
      case Right.Kind is
         when Number => 
            return (Kind => Number, Number_Val => Left + Right.Number_Val); 
         when Int => 
            return (Kind => Number, Number_Val => Left + Float (Right.Int_Val));
         when others =>
            raise Unsupported with 
              "Cannot add a " & To_String (Right.Kind) & " to a Float"; 
      end case;
   end "+";
   
   function "+" (Left: Integer; Right: ExprVal) return ExprVal is
   begin
      case Right.Kind is
         when Number => 
            return (Kind => Int, Int_Val => Left + Right.Int_Val);
         when Int =>
            return (Kind => Int, Int_Val => Left + Integer (Right.Number_Val));
         when others =>
            raise Unsupported with 
              "Cannot add a " & To_String (Right.Kind) & " to an Int";
      end case;
   end;
   
   function "+" (Left: Unbounded_Text_Type; Right: ExprVal) return ExprVal is
   begin
      case Right.Kind is
         when Number =>
            return (Kind => Str, Str_Val => Left & Float'Wide_Wide_Image(Right.Number_Val));
         when Int =>
            return (Kind => Str, Str_Val => Left & Integer'Wide_Wide_Image(Right.Int_Val));
         when Str =>
            return (Kind => Str, Str_Val => Left & Right.Str_Val);
         when others =>
            raise Unsupported with 
              "Cannot add a " & To_String (Right.Kind) & " to a Str";
      end case;
   end "+";
   
end Interpreter.Values;
