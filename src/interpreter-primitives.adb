with Libadalang.Introspection; use Libadalang.Introspection;

with Ada.Strings.Wide_Wide_Unbounded; use Ada.Strings.Wide_Wide_Unbounded;
with Ada.Strings.Wide_Wide_Unbounded.Wide_Wide_Text_IO;
use Ada.Strings.Wide_Wide_Unbounded.Wide_Wide_Text_IO;

with GNAT.Case_Util;

package body Interpreter.Primitives is
   subtype Field_Index is Integer range -1 .. Integer'Last;
   --  Represents the index of an AST node's field, retrieved using the
   --  introspection API.
   --  -1 is used to represent invalid fields

   function Int_Image (Value : Integer) return Unbounded_Text_Type;
   --  Wraps the Integer'Wide_Wide_Image function, removing the leading space

   function Bool_Image (Value : Boolean) return Unbounded_Text_Type;
   --  Return a String representation of the given Boolean value

   function Generator_Image (Value : Generator) return Unbounded_Text_Type;

   function List_Image (Value : Primitive_List) return Unbounded_Text_Type;
   --  Return a String representation of the given Primitive_List value

   procedure Check_Kind (Expected_Kind : Primitive_Kind; Value : Primitive);
   --  Raise an Unsupporter_Error exception if Value.Kind is different than
   --  Expected_Kind.

   function Get_Field_Index
     (Name : Text_Type; Node : LAL.Ada_Node) return Field_Index;
   --  Return the index of 'Node's field named 'Name', or -1 if there is no
   --  field matching the given name.

   function List_Property (Value : Primitive_List_Access;
                           Property_Name : Text_Type) return Primitive;
   --  Return the value of the property named 'Property_Name' of the given
   --  Primitive List.
   --  Raise an Unsupported_Error if there is no property named
   --  'Property_Name'.

   function Str_Property
     (Value : Unbounded_Text_Type; Property_Name : Text_Type) return Primitive;
   --  Return the value of the property named 'Property_Name' of the given
   --  Str value.
   --  Raise an Unsupported_Error if there is no property named
   --  'Property_Name'.

   function Node_Property
     (Value : LAL.Ada_Node; Property_Name : Text_Type) return Primitive;
   --  Return the value of the property named 'Property_Name' of the given
   --  Node value.
   --  Raise an Unsupported_Error if there is no property named
   --  'Property_Name'.

   ---------------
   -- Int_Image --
   ---------------

   function Int_Image (Value : Integer) return Unbounded_Text_Type is
      Image : constant Text_Type := Integer'Wide_Wide_Image (Value);
   begin
      return To_Unbounded_Text (Image (2 .. Image'Last));
   end Int_Image;

   -----------------
   --  Bool_Image --
   -----------------

   function Bool_Image (Value : Boolean) return Unbounded_Text_Type is
      use GNAT.Case_Util;
      Image : String := Boolean'Image (Value);
   begin
      To_Lower (Image);
      return To_Unbounded_Text (To_Text (Image));
   end Bool_Image;

   ----------------
   -- List_Image --
   ----------------

   function List_Image (Value : Primitive_List) return Unbounded_Text_Type is
      use Langkit_Support.Text.Chars;
      Image : Unbounded_Text_Type;
   begin
      for Element of Value.Elements loop
         Append (Image, To_Unbounded_Text (Element) & LF);
      end loop;

      return Image;
   end List_Image;

   function Generator_Image (Value : Generator) return Unbounded_Text_Type is
   begin
      return List_Image (List_Val (To_List (Value)).all);
   end Generator_Image;

   ----------------
   -- Check_Kind --
   ----------------

   procedure Check_Kind (Expected_Kind : Primitive_Kind; Value : Primitive) is
   begin
      if Kind (Value) /= Expected_Kind then
         raise Unsupported_Error
           with "Expected " & To_String (Expected_Kind) & " but got " &
                Kind_Name (Value);
      end if;
   end Check_Kind;

   ---------------------
   -- Get_Field_Index --
   ---------------------

   function Get_Field_Index
     (Name : Text_Type; Node : LAL.Ada_Node) return Field_Index
   is
      UTF8_Name : constant String := To_UTF8 (Name);
   begin
      for F of Fields (Node.Kind) loop
         if Field_Name (F) = UTF8_Name then
            return Index (Node.Kind, F);
         end if;
      end loop;

      return -1;
   end Get_Field_Index;

   -------------
   -- Release --
   -------------

   procedure Release (Data : in out Primitive_Data) is
   begin
      if Data.Kind /= Kind_List then
         return;
      end if;

      Free_Primitive_List (Data.List_Val);
   end Release;

   ----------
   -- Next --
   ----------

   function Next
     (Iter : in out Generator; Result : out Primitive) return Boolean
   is
   begin
      return Iter.Iter.Next (Result);
   end Next;

   -----------
   -- Clone --
   -----------

   overriding function Clone (Gen : Generator) return Generator is
      Iter_Copy : constant Primitive_Iter_Access :=
        new Primitive_Iters.Iterator_Interface'Class'(Gen.Iter.all);
   begin
      return Generator'(Gen.Elements_Kind, Iter_Copy);
   end Clone;

   -------------
   -- Release --
   -------------

   overriding procedure Release (Gen : in out Generator) is
   begin
      Free_Primitive_Iter (Gen.Iter);
   end Release;

   -------------
   -- To_List --
   -------------

   function To_List (Gen : Generator) return Primitive is
      Element  : Primitive;
      Gen_Copy : constant Generator := Gen.Clone;
      Result   : constant Primitive := Make_Empty_List (Gen.Elements_Kind);
   begin
      while Gen_Copy.Iter.Next (Element) loop
         Append (Result, Element);
      end loop;

      return Result;
   end To_List;

   ----------
   -- Next --
   ----------

   overriding function Next (Iter   : in out Primitive_Vector_Iter;
                             Result : out Primitive) return Boolean
   is
   begin
      if Iter.Next_Pos >= Positive (Iter.Values.Length) then
         return False;
      end if;

      Result := Iter.Values.all (Iter.Next_Pos);
      Iter.Next_Pos := Iter.Next_Pos + 1;
      return True;
   end Next;

   -----------
   -- Clone --
   -----------

   overriding function Clone
     (Iter : Primitive_Vector_Iter) return Primitive_Vector_Iter
   is
      Values_Copy : constant Primitive_Vector_Access :=
        new Primitive_Vectors.Vector'(Iter.Values.all);
   begin
      return (Iter.Next_Pos, Values_Copy);
   end Clone;

   -------------
   -- Release --
   -------------

   procedure Release (Iter : in out Primitive_Vector_Iter) is
   begin
      Free_Primitive_Vector (Iter.Values);
   end Release;

   ----------
   -- Kind --
   ----------

   function Kind (Value : Primitive) return Primitive_Kind is
   begin
      return Value.Get.Kind;
   end Kind;

   -------------
   -- Int_Val --
   -------------

   function Int_Val (Value : Primitive) return Integer is
   begin
      return Value.Get.Int_Val;
   end Int_Val;

   -------------
   -- Str_Val --
   -------------

   function Str_Val (Value : Primitive) return Unbounded_Text_Type is
   begin
      return Value.Get.Str_Val;
   end Str_Val;

   --------------
   -- Bool_Val --
   --------------

   function Bool_Val (Value : Primitive) return Boolean is
   begin
      return Value.Get.Bool_Val;
   end Bool_Val;

   --------------
   -- Node_Val --
   --------------

   function Node_Val (Value : Primitive) return LAL.Ada_Node is
   begin
      return Value.Get.Node_Val;
   end Node_Val;

   --------------
   -- List_Val --
   --------------

   function List_Val (Value : Primitive) return Primitive_List_Access is
   begin
      return Value.Get.List_Val;
   end List_Val;

   -------------------
   -- Elements_Kind --
   -------------------

   function Elements_Kind (Value : Primitive) return Primitive_Kind is
   begin
      return (case Value.Get.Kind is
              when Kind_List => Value.Get.List_Val.Elements_Kind,
              when Kind_Generator => Value.Get.Gen_Val.Elements_Kind,
              when others =>
                 raise Program_Error with
                    "No property 'Elements_Kind' for values of kind: " &
                    Kind_Name (Value));
   end Elements_Kind;

   --------------
   -- Elements --
   --------------

   function Elements
     (Value : Primitive) return not null Primitive_Vector_Access is
   begin
      return Value.Get.List_Val.Elements'Access;
   end Elements;

   -------------------
   -- List_Property --
   -------------------

   function List_Property (Value : Primitive_List_Access;
                           Property_Name : Text_Type) return Primitive
   is
   begin
      if Property_Name = "length" then
         return To_Primitive (Integer (Value.Elements.Length));
      else
         raise Unsupported_Error with
           "No property named " & To_UTF8 (Property_Name) &
           " on values of kind " & To_String (Kind_List);
      end if;
   end List_Property;

   ------------------
   -- Str_Property --
   ------------------

   function Str_Property
     (Value : Unbounded_Text_Type; Property_Name : Text_Type) return Primitive
   is
   begin
      if Property_Name = "length" then
         return To_Primitive (Length (Value));
      else
         raise Unsupported_Error with
           "No property named " & To_UTF8 (Property_Name) &
           " on values of kind " & To_String (Kind_Str);
      end if;
   end Str_Property;

   -------------------
   -- Node_Property --
   -------------------

   function Node_Property
     (Value : LAL.Ada_Node; Property_Name : Text_Type) return Primitive
   is
      Index : constant Field_Index :=
        Get_Field_Index (Property_Name, Value);
   begin

      if Index = -1 then
         raise Unsupported_Error with
           "No field named " & To_UTF8 (Property_Name) &
           " on values of kind " & To_String (Kind_Node);
      end if;

      return To_Primitive (Value.Children (Index));
   end Node_Property;

   --------------
   -- Property --
   --------------

   function Property
     (Value : Primitive; Property_Name : Text_Type) return Primitive
   is
   begin
      return (case Kind (Value) is
                 when Kind_List =>
                   List_Property (List_Val (Value), Property_Name),
                 when Kind_Str =>
                   Str_Property (Str_Val (Value), Property_Name),
                 when Kind_Node =>
                   Node_Property (Node_Val (Value), Property_Name),
                 when others =>
                    raise Unsupported_Error with
                      "Values of kind " & Kind_Name (Value) &
                      " dont have properties");
   end Property;

   -------------------------
   -- Make_Unit_Primitive --
   -------------------------

   function Make_Unit_Primitive return Primitive is
      Ref : Primitive;
   begin
      Ref.Set (Primitive_Data'(Refcounted with Kind => Kind_Unit));
      return Ref;
   end Make_Unit_Primitive;

   ------------------
   -- To_Primitive --
   ------------------

   function To_Primitive (Val : Integer) return Primitive is
      Ref : Primitive;
   begin
      Ref.Set
        (Primitive_Data'(Refcounted with Kind => Kind_Int, Int_Val => Val));
      return Ref;
   end To_Primitive;

   ------------------
   -- To_Primitive --
   ------------------

   function To_Primitive (Val : Unbounded_Text_Type) return Primitive is
      Ref : Primitive;
   begin
      Ref.Set
        (Primitive_Data'(Refcounted with Kind => Kind_Str, Str_Val => Val));
      return Ref;
   end To_Primitive;

   ------------------
   -- To_Primitive --
   ------------------

   function To_Primitive (Val : Boolean) return Primitive is
      Ref : Primitive;
   begin
      Ref.Set
        (Primitive_Data'(Refcounted with Kind => Kind_Bool, Bool_Val => Val));
      return Ref;
   end To_Primitive;

   ------------------
   -- To_Primitive --
   ------------------

   function To_Primitive (Val : LAL.Ada_Node) return Primitive is
      Ref : Primitive;
   begin
      Ref.Set
        (Primitive_Data'(Refcounted with Kind => Kind_Node, Node_Val => Val));
      return Ref;
   end To_Primitive;

   ---------------------
   -- Make_Empty_List --
   ---------------------

   function Make_Empty_List (Kind : Primitive_Kind) return Primitive is
      Ref  : Primitive;
      List : constant Primitive_List_Access :=
        new Primitive_List'(Elements_Kind => Kind,
                            Elements      => Primitive_Vectors.Empty_Vector);
   begin
      Ref.Set (Primitive_Data'(Refcounted with Kind     => Kind_List,
                                               List_Val => List));
      return Ref;
   end Make_Empty_List;

   ------------
   -- Append --
   ------------

   procedure Append (List, Element : Primitive) is
      List_Elements : constant Primitive_Vector_Access :=
        Elements (List);
   begin
      Check_Kind (Kind_List, List);
      Check_Kind (Elements_Kind (List), Element);
      List_Elements.Append (Element);
   end Append;

   --------------
   -- Contains --
   --------------

   function Contains (List, Value : Primitive) return Boolean is
   begin
      Check_Kind (Kind_List, List);
      Check_Kind (Elements_Kind (List), Value);

      --  Since we're using smart pointers, the "=" function used by
      --  Vector.Contains checks referencial equality instead of structural
      --  equality. So the iteration "has" to be done manually.
      for Elem of List.Get.List_Val.Elements loop
         if Elem.Get = Value.Get then
            return True;
         end if;
      end loop;

      return False;
   end Contains;

   ---------
   -- Get --
   ---------

   function Get (List : Primitive; Index : Integer) return Primitive is
      Vec : Primitive_Vector_Access;
   begin
      Check_Kind (Kind_List, List);
      Vec := Elements (List);

      if Index not in Vec.First_Index .. Vec.Last_Index then
         raise Unsupported_Error
           with "Invalid index: " & Integer'Image (Index);
      end if;

      return Vec.Element (Positive (Index));
   end Get;

   ------------
   -- Length --
   ------------

   function Length (List : Primitive) return Natural is
   begin
      Check_Kind (Kind_List, List);
      return Natural (Elements (List).Length);
   end Length;

   -----------------------
   -- To_Unbounded_Text --
   -----------------------

   function To_Unbounded_Text (Val : Primitive) return Unbounded_Text_Type is
   begin
      return (case Kind (Val) is
                 when Kind_Unit =>
                   To_Unbounded_Text (To_Text ("()")),
                 when Kind_Int  =>
                   Int_Image (Int_Val (Val)),
                 when Kind_Str  =>
                   Str_Val (Val),
                 when Kind_Bool =>
                   Bool_Image (Bool_Val (Val)),
                 when Kind_Node =>
                   To_Unbounded_Text (Val.Get.Node_Val.Text_Image),
                 when Kind_Generator =>
                   Generator_Image (Val.Get.Gen_Val.all),
                 when Kind_List =>
                   List_Image (Val.Get.List_Val.all));
   end To_Unbounded_Text;

   ---------------
   -- To_String --
   ---------------

   function To_String (Val : Primitive_Kind) return String is
   begin
      return (case Val is
                 when Kind_Unit      => "Unit",
                 when Kind_Int       => "Int",
                 when Kind_Str       => "Str",
                 when Kind_Bool      => "Bool",
                 when Kind_Node      => "Node",
                 when Kind_Generator => "Generator",
                 when Kind_List      => "List");
   end To_String;

   ---------------
   -- Kind_Name --
   ---------------

   function Kind_Name (Value : Primitive) return String is
   begin
      return (case Value.Get.Kind is
                 when Kind_Unit =>
                   "Unit",
                 when Kind_Int =>
                   "Int",
                 when Kind_Str =>
                   "Str",
                 when Kind_Bool =>
                   "Bool",
                 when Kind_Node =>
                   LAL.Kind_Name (Value.Get.Node_Val),
                 when Kind_Generator =>
                   "Generator[" & To_String (Elements_Kind (Value)) & ']',
                 when Kind_List =>
                   "List[" & To_String (Elements_Kind (Value)) & ']');
   end Kind_Name;

   -------------
   -- Display --
   -------------

   procedure Display (Value : Primitive) is
   begin
      Put_Line (To_Unbounded_Text (Value));
   end Display;

   ---------
   -- "+" --
   ---------

   function "+" (Left, Right : Primitive) return Primitive is
   begin
      Check_Kind (Kind_Int, Left);
      Check_Kind (Kind_Int, Right);
      return To_Primitive (Int_Val (Left) + Int_Val (Right));
   end "+";

   ---------
   -- "-" --
   ---------

   function "-" (Left, Right : Primitive) return Primitive is
   begin
      Check_Kind (Kind_Int, Left);
      Check_Kind (Kind_Int, Right);
      return To_Primitive (Int_Val (Left) - Int_Val (Right));
   end "-";

   ---------
   -- "*" --
   ---------

   function "*" (Left, Right : Primitive) return Primitive is
   begin
      Check_Kind (Kind_Int, Left);
      Check_Kind (Kind_Int, Right);
      return To_Primitive (Int_Val (Left) * Int_Val (Right));
   end "*";

   --------
   -- "/"--
   --------

   function "/" (Left, Right : Primitive) return Primitive is
   begin
      Check_Kind (Kind_Int, Left);
      Check_Kind (Kind_Int, Right);

      if Int_Val (Right) = 0 then
         raise Unsupported_Error with "Zero division";
      end if;

      return To_Primitive (Int_Val (Left) / Int_Val (Right));
   end "/";

   ---------
   -- "=" --
   ---------

   function "=" (Left, Right : Primitive) return Primitive is
   begin
      if Kind (Left) /= Kind (Right) then
         raise Unsupported_Error
           with "Cannot check equality between a " & Kind_Name (Left) &
                " and a " & Kind_Name (Right);
      end if;

      return To_Primitive (Left.Get = Right.Get);
   end "=";

   ----------
   -- "/=" --
   ----------

   function "/=" (Left, Right : Primitive) return Primitive is
      Eq : constant Primitive := Left = Right;
   begin
      return To_Primitive (not Bool_Val (Eq));
   end "/=";

   ---------
   -- "&" --
   ---------

   function "&" (Left, Right : Primitive) return Primitive is
      Left_Str  : Unbounded_Text_Type;
      Right_Str : Unbounded_Text_Type;
   begin
      Check_Kind (Kind_Str, Left);
      Left_Str := Str_Val (Left);

      Right_Str := (case Kind (Right) is
                    when Kind_Int  => Int_Image (Int_Val (Right)),
                    when Kind_Str  => Str_Val (Right),
                    when Kind_Bool => Bool_Image (Bool_Val (Right)),
                    when others =>
                       raise Unsupported_Error with
                         "Cannot add a " & Kind_Name (Right) & " to a Str");

      return To_Primitive (Left_Str & Right_Str);
   end "&";

end Interpreter.Primitives;
