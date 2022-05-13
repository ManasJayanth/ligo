const common = require('../common.js')

module.exports = grammar({
  name: 'JsLigo',

  word: $ => $.Keyword,
  externals: $ => [$.ocaml_comment, $.comment, $.line_marker, $._js_ligo_attribute, $._automatic_semicolon],
  extras: $ => [$.ocaml_comment, $.comment, $.line_marker, $._js_ligo_attribute, /\s/],

  conflicts: $ => [
    [$.variant],
    [$.module_access],
    [$._expr_statement, $.data_projection],
    [$.annot_expr, $.parameter],
    [$.variant, $.string_type],
    [$._member_expr, $.Nat, $.Tez],
    [$.Int, $.Nat, $.Tez]
  ],

  rules: {
    source_file: $ =>
      common.sepEndBy(optional($._semicolon), field("toplevel", $._statement_or_namespace_or_preprocessor)),

    _statement_or_namespace_or_preprocessor: $ => choice($._statement, $.namespace_statement, $.preprocessor),

    namespace_statement: $ => prec.left(2, seq(
      optional(field("export", 'export')), 'namespace', field("moduleName", $.ModuleName),
      '{',
      common.sepEndBy($._semicolon, field("declaration", $._statement_or_namespace_or_preprocessor)),
      '}',
      optional($._automatic_semicolon)
    )),

    _statement: $ => prec.right(1, field("statement", choice($._base_statement, $.if_statement))),

    if_statement: $ => seq('if', field("selector", common.par($._expr)), field("then", $._statement)),

    _base_statement: $ => prec(5, choice(
      $._expr_statement,
      $.return_statement,
      $.block_statement,
      $.switch_statement,
      $.import_statement,
      $.export_statement,
      $._declaration_statement,
      $.if_else_statement,
      $.for_of_statement,
      $.while_statement,
      $.break_statement
    )),

    break_statement: $ => 'break',

    _expr_statement: $ => choice(
      $.fun_expr,
      $.assignment_operator,
      $.binary_call,
      $.unary_call,
      $.call_expr,
      $._member_expr,
      $.match_expr,
      $.type_as_annotation,
    ),

    assignment_operator: $ => prec.right(2,
      seq(field("lhs", $._expr_statement),
      field("op", choice('=', '*=', '/=', '%=', '+=', '-=')),
      field("rhs", $._expr_statement))
    ),

    type_as_annotation: $ => seq(field("subject", $._expr_statement), 'as', field("type", $._core_type)),

    binary_call: $ => choice(
      prec.left(4,  seq(field("left", $._expr_statement), field("op", '||'), field("right", $._expr_statement))),
      prec.left(5,  seq(field("left", $._expr_statement), field("op", '&&'), field("right", $._expr_statement))),
      prec.left(10, seq(field("left", $._expr_statement), field("op", choice('<', '<=', '>', '>=', '==', '!=')), field("right", $._expr_statement))),
      prec.left(12, seq(field("left", $._expr_statement), field("op", choice('+', '-')),      field("right", $._expr_statement))),
      prec.left(13, seq(field("left", $._expr_statement), field("op", choice('*', '/', '%')), field("right", $._expr_statement)))
    ),

    unary_call: $ => prec.right(15, seq(field("negate", choice('-', '!')), field("arg", $._expr_statement))),

    call_expr: $ => prec.right(2, seq(field("f", $.lambda), $.arguments)),

    arguments: $ => common.par(common.sepBy(',', field("argument", $._annot_expr))),

    lambda: $ => prec(5, choice($.call_expr, $._member_expr)),

    _expr: $ => choice($._expr_statement, $.object_literal),

    _annot_expr: $ => choice(
      $.annot_expr,
      $._expr,
    ),

    annot_expr: $ => seq(
      field("subject", $._expr),
      $._type_annotation
    ),

    match_expr: $ => seq('match', common.par(seq(field("subject", $._member_expr), ',', field("alt", choice($._list_cases, $._ctor_cases))))),

    _list_cases: $ => seq('list',
      common.par(
        common.brackets(
          common.sepBy1(',',
            $.list_case
          )
        )
      )
    ),

    list_case: $ => seq(
      field("pattern", common.par(seq($.array_literal, optional($._type_annotation)))),
      '=>',
      field("body", $.body)
    ),

    _ctor_cases: $ => common.block(
      common.sepBy1(',',
        $.ctor_case
      )
    ),

    ctor_param: $ => seq($._expr, $._type_annotation),

    ctor_case: $ => seq(
      field("pattern", $.ConstrName),
      ':',
      common.par(common.sepBy(',', $.ctor_param)),
      '=>',
      field("body", $.body)
    ),

    _member_expr: $ => choice(
      $.Name,
      $.Int,
      $.Bytes,
      $.String,
      $.Nat,
      $.Tez,
      $._Bool,
      $.Unit_kwd,
      $.ctor_expr,
      $.data_projection,
      $.michelson_interop,
      $.paren_expr,
      $.module_access,
      $.array_literal,
      $.wildcard
    ),

    paren_expr: $ => common.par(field("expr", $._annot_expr)),

    ctor_expr: $ => seq(field("ctor", $.ConstrName), field("args", $.ctor_args)),

    ctor_args: $ => common.par(common.sepBy(',', $._expr)),

    data_projection: $ => choice(
      seq(field("field", $._member_expr), common.brackets(field("accessor", $._expr))),
      seq(field("field", $._member_expr), '.', $._accessor_chain)
    ),

    _accessor_chain: $ => prec.right(common.sepBy1('.', field("accessor", $.Name))),

    michelson_interop: $ => seq(
      '(Michelson',
        seq(
          field("code", $.michelson_code),
          'as',
          field("type", $._core_type),
        ),
      ')'
    ),

    michelson_code: $ => seq('`', repeat(/([^\|]|\|[^}])/), '`'),

    module_access: $ => seq(
      common.sepBy1('.', field("path", $.ModuleName)),
      '.',
      field("field", $.FieldName),
    ),

    array_literal: $ => choice(common.brackets(common.sepBy(',', field("element", $._array_item)))),

    _array_item: $ => choice($._annot_expr, $.array_item_rest_expr),

    array_item_rest_expr: $ => seq('...', field("expr", $._expr)),

    fun_expr: $ => choice(
      seq(
        common.par($._parameters),
        optional(field("type", $._type_annotation)), '=>',
        field("body", $.body),
      ),
      seq(
        '(', ')',
        optional(field("type", $._type_annotation)), '=>',
        field("body", $.body),
      ),
      seq(
        field("argument", $.Name), '=>',
        field("body", $.body),
      )
    ),

    body: $ => prec.right(3, choice(seq('{', $._statements, '}', optional($._automatic_semicolon)), $._expr_statement)),

    _statements: $ => common.sepEndBy1($._semicolon, $._statement),

    _type_annotation: $ => seq(':', seq(optional($.type_params), field("type", $._type_expr))),

    _parameters: $ => common.sepBy1(',', field("argument", $.parameter)),

    parameter: $ => seq(field("expr", $._expr), field("type", $._type_annotation)),

    return_statement: $ => prec.left(2, seq('return', field("expr", optional($._expr)))),

    block_statement: $ => prec.left(2, seq('{', $._statements, '}', optional($._automatic_semicolon))),

    object_literal: $ => common.block(common.sepBy(',', $.property)),

    property: $ => choice($.Name, seq(field("property_name", $.property_name), ':', field("expr", $._expr)), $._property_spread),

    _property_spread: $ => seq('...', field("spread_expr", $._expr_statement)),

    property_name: $ => choice($.Int, $.String, $.ConstrName, $.Name),

    _type_expr: $ => choice(
      $.fun_type,
      $.sum_type,
      $._core_type
    ),

    fun_type: $ => seq(field("domain", common.par(common.sepBy(',', $._fun_param))), '=>', field("codomain", $._type_expr)),

    _fun_param: $ => seq($._Name, field("type", $._type_annotation)),

    sum_type: $ => prec.right(1, common.withAttrs($, seq(optional('|'), common.sepBy1('|', field("variant", $.variant))))),

    variant: $ => common.withAttrs($, common.brackets(
      choice(
        field("constructor", $.String),
        seq(field("constructor", $.String), ',', field("arguments", common.sepBy1(',', $._type_expr)))
      )
    )),

    _core_type: $ => choice(
      $.Int,
      $.TypeWildcard,
      $.TypeName,
      $.string_type,
      $.module_access_t,
      $.record_type,
      $.app_type,
      common.withAttrs($, $.tuple_type),
      common.par($._type_expr)
    ),

    string_type: $ => field("value", $.String),

    module_access_t: $ => seq(common.sepBy1('.', field("path", $.ModuleName)), '.', field("type", $.Name)),

    record_type: $ => common.withAttrs($, common.block(common.sepEndBy(',', field("field", $.field_decl)))),

    field_decl: $ => common.withAttrs($, choice(
      field("field_name", $.FieldName),
      seq(field("field_name", $.FieldName), field("field_type", $._type_annotation))
    )),

    app_type: $ => prec(3, seq(field("functor", $.TypeName), common.chev(common.sepBy1(',', field("argument", $._type_expr))))),

    tuple_type: $ => common.brackets(common.sepBy1(',', field("element", $._type_expr))),

    import_statement: $ => seq('import', field("moduleName", $.ModuleName), '=', common.sepBy1('.', field("module", $.ModuleName))),

    export_statement: $ => seq(field("export", 'export'), $._declaration_statement),

    _declaration_statement: $ => choice(
      $._let_decls,
      $._const_decls,
      $.type_decl
    ),

    type_decl: $ => seq("type", field("type_name", $.TypeName), optional(field("params", $.type_params)), '=', field("type_value", $._type_expr)),

    type_params: $ => common.chev(common.sepBy1(',', field("param", $.var_type))),

    var_type: $ => field("name", $.TypeVariableName),

    _let_decls: $ => common.withAttrs($, seq('let', common.sepBy1(',', $.let_decl))),

    _const_decls: $ => common.withAttrs($, seq('const', common.sepBy1(',', $.const_decl))),

    let_decl: $ => $._binding_initializer,

    const_decl: $ => $._binding_initializer,

    _binding_initializer: $ => seq(
      field("binding", $._binding_pattern), 
      optional(
        seq(
          optional($.type_params), 
          field("type", $._type_annotation)
        )
      ), 
      '=', 
      field("value", $._expr)
    ),

    _binding_pattern: $ => choice(
      $.var_pattern,
      $.wildcard,
      $.object_pattern,
      $.array_pattern
    ),

    var_pattern: $ => common.withAttrs($, $.NameDecl),

    object_pattern: $ => common.block($.property_patterns),

    property_patterns: $ => choice(
      $.property_pattern,
      seq($.property_patterns, ',', $.property_pattern),
      seq($.property_patterns, ',', $.object_rest_pattern)
    ),

    property_pattern: $ => choice(
      seq($.FieldName, '=', $._expr),
      seq($.FieldName, ':', $._binding_initializer),
      $.var_pattern,
    ),

    object_rest_pattern: $ => seq('...', $.NameDecl),

    array_pattern: $ => common.brackets($._array_item_patterns),

    _array_item_patterns: $ => choice(
      $._array_item_pattern,
      seq($._array_item_patterns, ',', $._array_item_pattern),
      seq($._array_item_patterns, ',', $.array_rest_pattern)
    ),

    _array_item_pattern: $ => choice(
      $.var_pattern,
      $.wildcard,
      $.array_pattern
    ),

    array_rest_pattern: $ => seq('...', field("name", $.Name)),

    switch_statement: $ => seq('switch', common.par(field("selector", $._expr)), field("cases", common.block($._cases))),

    _cases: $ => choice(
      seq(repeat1($.case), optional($.default_case)),
      $.default_case
    ),

    case: $ => seq('case', field("selector_value", $._expr), field("body", $._case_statements)),

    default_case: $ => seq('default', field("body", $._case_statements)),

    _case_statements: $ => seq(':', choice(
      optional($._statements),
      $.block_statement,
    )),

    if_else_statement: $ => seq('if', field("selector", common.par($._expr)), field("then", $._base_statement), 'else', field("else", $._statement)),

    for_of_statement: $ => seq('for', common.par(seq($._index_kind, field("key", $.Name), 'of', field("collection", $._expr_statement))), field("body", $._statement)),

    _index_kind: $ => choice($.Let_kwd, $.Const_kwd),

    while_statement: $ => seq('while', field("breaker", common.par($._expr)), field("body", $._statement)),

    /// PREPROCESSOR

    // copied from cameligo/grammar.js

    preprocessor: $ => field("preprocessor_command", choice(
      $.p_include,
      $.p_import,
      $.p_if,
      $.p_error,
      $.p_define,
    )),

    p_include: $ => seq(
      '#',
      'include',
      field("filename", $.String)
    ),

    p_import: $ => seq(
      '#',
      'import',
      field("filename", $.String),
      field("alias", $.String),
    ),

    p_if: $ => choice(
      seq(
        '#',
        choice('if', 'elif', 'else'),
        field("rest", $._till_newline),
      ),
      seq(
        '#',
        'endif',
      ),
    ),

    p_error: $ => seq('#', 'error', field("message", $._till_newline)),
    p_define: $ => seq('#', choice('define', 'undef'), field("definition", $._till_newline)),

    _semicolon: $ => choice(';', $._automatic_semicolon),

    ConstrName: $ => $._NameCapital,
    FieldName: $ => $._Name,
    ModuleName: $ => $._NameCapital,
    TypeName: $ => choice($._Name, $._NameCapital),
    TypeVariableName: $ => choice($._Name, $._NameCapital),
    Name: $ => $._Name,
    NameDecl: $ => $._Name,

    _till_newline: $ => /[^\n]*\n/,

    attr: $ => $._js_ligo_attribute,

    String: $ => /\"(\\.|[^"])*\"/,
    _Int: $ => /-?([1-9][0-9_]*|0)/,
    Int: $ => $._Int,
    Nat: $ => seq($._Int, 'as', 'nat'),
    Tez: $ => seq($._Int, 'as', choice('tez', 'mutez')),
    Bytes: $ => /0x[0-9a-fA-F]+/,

    _Name: $ => /[a-z][a-zA-Z0-9_]*|_(?:_?[a-zA-Z0-9])+/,
    _NameCapital: $ => /[A-Z][a-zA-Z0-9_]*/,
    TypeWildcard: $ => '_',
    Keyword: $ => /[A-Za-z][a-z]*/,
    _Bool: $ => choice($.False_kwd, $.True_kwd),

    Unit_kwd: $ => 'unit',
    False_kwd: $ => 'false',
    True_kwd: $ => 'true',
    wildcard: $ => '_',
    Let_kwd: $ => 'let',
    Const_kwd: $ => 'const',
  }
})