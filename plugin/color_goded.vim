" Vim global plugin for semantic highlighting using libclang
" Maintainer:	Jeaye <contact@jeaye.com>

" ------------------------------------------------------------------------------
if v:version < 704 || !exists("*matchaddpos")
  echohl WarningMsg |
        \ echomsg "color_goded unavailable: requires Vim 7.4p330+" |
        \ echohl None
  finish
endif
if has('nvim')
  echohl WarningMsg |
        \ echomsg "color_goded unavailable: nvim isn't yet supported" |
        \ echohl None
  finish
endif
if !has('lua')
  echohl WarningMsg |
        \ echomsg "color_goded unavailable: requires lua" |
        \ echohl None
  finish
endif

if exists("g:loaded_color_goded") || &cp
  finish
endif

if !exists("g:color_goded_enabled")
  let g:color_goded_enabled = 1
elseif g:color_goded_enabled == 0
  finish
endif
" ------------------------------------------------------------------------------

let g:loaded_color_goded = 1
let $VIMHOME = expand('<sfile>:p:h:h')
let s:keepcpo = &cpo
set cpo&vim
" ------------------------------------------------------------------------------

" Only continue if the setup went well
let s:color_goded_valid = color_goded#setup()
if s:color_goded_valid == 1
  command! CCerror call color_goded#last_error()
  command! CCtoggle call color_goded#toggle()

  augroup color_goded
    au VimEnter,ColorScheme * source $VIMHOME/after/syntax/color_goded.vim
    au BufEnter * call color_goded#enter()
    au WinEnter * call color_goded#enter()
    au TextChanged,TextChangedI * call color_goded#push()
    au CursorMoved,CursorMovedI * call color_goded#moved()
    au CursorHold,CursorHoldI * call color_goded#moved()
    " Resized events trigger midway through a vim state change; the buffer
    " name will still be the previous buffer, yet the window-specific
    " variables won't be available.
    "au VimResized * call color_goded#moved()

    " Leaving a color_goded buffer requires removing matched positions
    au BufLeave * call color_goded#clear_matches(color_goded#get_buffer_name())

    " There is a rogue BufDelete at the start of vim; the buffer name ends up
    " being relative, so it's not a bother, but it's certainly odd.
    au BufDelete * call color_goded#destroy()
    au VimLeave * call color_goded#exit()
  augroup END

  nnoremap <silent> <ScrollWheelUp>
        \ <ScrollWheelUp>:call color_goded#moved()<CR>
  inoremap <silent> <ScrollWheelUp>
        \ <ScrollWheelUp><ESC>:call color_goded#moved()<CR><INS>
  nnoremap <silent> <ScrollWheelDown>
        \ <ScrollWheelDown>:call color_goded#moved()<CR>
  inoremap <silent> <ScrollWheelDown>
        \ <ScrollWheelDown><ESC>:call color_goded#moved()<CR><INS>

  nnoremap <silent> <S-ScrollWheelUp>
        \ <S-ScrollWheelUp>:call color_goded#moved()<CR>
  inoremap <silent> <S-ScrollWheelUp>
        \ <S-ScrollWheelUp><ESC>:call color_goded#moved()<CR><INS>
  nnoremap <silent> <S-ScrollWheelDown>
        \ <S-ScrollWheelDown>:call color_goded#moved()<CR>
  inoremap <silent> <S-ScrollWheelDown>
        \ <S-ScrollWheelDown><ESC>:call color_goded#moved()<CR><INS>

  nnoremap <silent> <C-ScrollWheelUp>
        \ <C-ScrollWheelUp>:call color_goded#moved()<CR>
  inoremap <silent> <C-ScrollWheelUp>
        \ <C-ScrollWheelUp><ESC>:call color_goded#moved()<CR><INS>
  nnoremap <silent> <C-ScrollWheelDown>
        \ <C-ScrollWheelDown>:call color_goded#moved()<CR>
  inoremap <silent> <C-ScrollWheelDown>
        \ <C-ScrollWheelDown><ESC>:call color_goded#moved()<CR><INS>
endif

" ------------------------------------------------------------------------------
let &cpo = s:keepcpo
unlet s:keepcpo
