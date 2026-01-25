; Custom aerial.scm for SQL - compatible with derekstride/tree-sitter-sql
; Overrides aerial.nvim's default which has PostgreSQL-specific nodes

(create_table
  (object_reference) @name
  (#set! "kind" "Class")) @symbol

(create_view
  (object_reference) @name
  (#set! "kind" "Class")) @symbol

(create_function
  (object_reference) @name
  (#set! "kind" "Function")) @symbol

(create_trigger
  (object_reference) @name
  (#set! "kind" "Class")) @symbol

(create_index
  column: (_) @name
  (#set! "kind" "Class")) @symbol
