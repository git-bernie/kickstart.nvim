; extends

; Inject htmldjango for HTML heredocs containing {{ (LoanConnect templates)
; Higher priority to override other injections
((nowdoc
  identifier: (heredoc_start) @_start
  value: (nowdoc_body) @injection.content)
 (#match? @_start "HTML")
 (#lua-match? @injection.content "{{")
 (#set! injection.language "htmldjango")
 (#set! injection.include-children)
 (#set! injection.priority 200))

((heredoc
  identifier: (heredoc_start) @_start
  value: (heredoc_body) @injection.content)
 (#match? @_start "HTML")
 (#lua-match? @injection.content "{{")
 (#set! injection.language "htmldjango")
 (#set! injection.include-children)
 (#set! injection.priority 200))
