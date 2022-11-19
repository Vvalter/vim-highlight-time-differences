" Vim plugin to highlight time differences in log files
" License: This file is placed in the public domain
if exists('g:loaded_highlight_time_differences')
    finish
endif
let g:loaded_highlight_time_differences = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -range=% HighlightTimeDifferences
    \ lua require("highlight-time-differences").HighlightTimeDifferences(<line1>, <line2>, {<f-args>})
command! -range=% HighlightTimeDifferencesClear lua require("highlight-time-differences").HighlightTimeDifferencesClear(<line1>, <line2>)

let &cpo = s:save_cpo
unlet s:save_cpo
