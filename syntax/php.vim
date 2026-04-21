" Treesitter handles PHP highlighting — skip Vim's heavy regex syntax chain
" (runtime php.vim pulls in html, css, javascript, sql, xml, vb = ~55ms)
let b:current_syntax = 'php'
