with LKQL.Errors;        use LKQL.Errors;
with LKQL.Eval_Contexts; use LKQL.Eval_Contexts;
with LKQL.Primitives;    use LKQL.Primitives;

with Libadalang.Introspection; use Libadalang.Introspection;

with Langkit_Support.Text;        use Langkit_Support.Text;

private package LKQL.Error_Handling is

   procedure Raise_And_Record_Error
     (Ctx : Eval_Context; Error : Error_Data)
      with No_Return;
   --  Add the given error to the evaluation context and:
   --    * raise a Recoverable_Error if error recovery is enabled and the
   --      user chooses to ignore the error
   --    * raise a Stop_Evaluation_Error if error recovery is disabled or the
   --      user chooses not to ignore the error

   procedure Raise_Invalid_Member (Ctx      : Eval_Context;
                                   Node     : L.Dot_Access;
                                   Receiver : Primitive)
      with No_Return;
   --  Raise an exception signaling an invalid member access, and add an
   --  Error_Data describing the error to the evaluation context.

   procedure Raise_Invalid_Member (Ctx      : Eval_Context;
                                   Node     : L.Identifier;
                                   Receiver : Primitive)
     with No_Return;
   --  Raise an exception signaling an invalid member access, and add an
   --  Error_Data describing the error to the evaluation context.

   procedure Raise_Null_Root (Ctx : Eval_Context; Node : L.Query)
      with No_Return;
   --  Raise an exception signaling the absence of a proper AST root while
   --  trying to execute a query, and add an Error_Data describing the error
   --  to the evaluation context.

   procedure Raise_Invalid_Kind (Ctx      : Eval_Context;
                                 Node     : L.LKQL_Node;
                                 Expected : Valid_Primitive_Kind;
                                 Value    : Primitive)
      with No_Return;
   --  Raise an exception signaling a type error, and add an Error_Data
   --  describing the error to the evaluation context.

   procedure Raise_Invalid_Selector_Name (Ctx  : Eval_Context;
                                          Node : L.Identifier)
     with No_Return;
   --  Raise an exception signaling the use of an invalid selector name,
   --  and add an Error_Data describing the error to the evaluation context.

   procedure Raise_Unknown_Symbol (Ctx  : Eval_Context;
                                   Node : L.Identifier)
     with No_Return;
   --  Raise an exception signaling the use of an unknwown identifier,
   --  and add an Error_Data describing the error to the evaluation context.

   procedure Raise_Already_Existing_Symbol (Ctx        : Eval_Context;
                                            Identifier : Unbounded_Text_Type;
                                            Node       : L.LKQL_Node)
     with No_Return;
   --  Raise an exception signaling an attempt to create a binding using a name
   --  that is already bound to a value in the local context,
   --  and add an Error_Data describing the error to the evaluation context.

   procedure Raise_Invalid_Arity (Ctx            : Eval_Context;
                                  Expected_Arity : Positive;
                                  Arguments      : L.Arg_List)
     with No_Return;
   --  Raise an exception signaling an attempt to call a function with an
   --  incorrect number of arguments,
   --  and add an Error_Data describing the error to the evaluation context.

   procedure Raise_Unknown_Argument (Ctx        : Eval_Context;
                                     Identifier : L.Identifier)
     with No_Return;
   --  Raise an exception signaling an attempt to call a functon with an
   --  argument which name doesn't match the name of a parameter, and add an
   --  Error_Data describing the error to the evaluation context.

   procedure Raise_Positionnal_After_Named (Ctx         : Eval_Context;
                                            Positionnal : L.Expr_Arg)
     with No_Return;
   --  Raise an exception signaling the use of a positonnal argument after a
   --  named argument, and add an Error_Data describing the error to the
   --  evaluation context.

   procedure Raise_Already_Seen_Arg (Ctx : Eval_Context;
                                     Arg : L.Named_Arg)
     with No_Return;
   --  Raise an exception signaling an attempt to call a function with
   --  at least two identically-named arguments.

   procedure Raise_Unsupported_Value_Type (Ctx       : Eval_Context;
                                           Node      : L.LKQL_Node;
                                           Kind      : Value_Kind)
     with No_Return;
   --  Raise an exception signaling the use of a value of a type that is not
   --  supported by the interpreter and add an Error_Data describing the error
   --  to the evaluation context. Such an error may occur when retriving
   --  a value from the introspection API.

   procedure Raise_Invalid_Type_Conversion (Ctx           : Eval_Context;
                                            Value_Expr    : L.Expr;
                                            Value         : Primitive;
                                            Expected_Kind : Value_Kind)
     with No_Return;
   --  Raise an exception signaling an invalid type conversion between a
   --  Primitive and a Value_Kind value from the introspection API,
   --  and add an Error_Data describing the error to the evaluation context.

   procedure Raise_Invalid_Kind_For_Selector (Ctx   : Eval_Context;
                                              Node  : L.LKQL_Node'Class;
                                              Value : Primitive)
     with No_Return;
   --  Raise an exception signaling the use of a value that is neither a node
   --  or an unpacked collection of nodes in a selector, and add an Error_Data
   --  describing the error to the evaluation context.

end LKQL.Error_Handling;