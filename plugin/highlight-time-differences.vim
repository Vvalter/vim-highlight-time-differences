" Vim plugin to highlight time differences in log files
" License: This file is placed in the public domain
if exists('g:loaded_highlight_time_differences')
    finish
endif
let g:loaded_highlight_time_differences = 1

let s:save_cpo = &cpo
set cpo&vim

command! HighlightTimeDifferences lua require("highlight-time-differences").HighlightTimeDifferences()

let &cpo = s:save_cpo
unlet s:save_cpo
