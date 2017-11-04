" Vim global plugin for semantic highlighting using libclang
" Maintainer:	Jeaye <contact@jeaye.com>

" Setup
" ------------------------------------------------------------------------------

let s:color_goded_api_version = 0x89084b5
let s:color_goded_valid = 1
let s:color_goded_unique_counter = 1
let g:color_goded_matches = {}

function! s:color_goded_create_defaults()
  if !exists("g:color_goded_filetypes")
    let g:color_goded_filetypes = ['go']
  endif
endfunction!

function! s:color_goded_define_lua_helpers()
  lua << EOF
    function color_goded_buffer_name()
      local name = vim.buffer().fname
      if (name == nil or name == '') then
        name = tostring(vim.buffer().number)
      end
      return name
    end

    function color_goded_buffer_details()
      local line_count = #vim.buffer()
      local buffer = vim.buffer()
      local data = {}
      for i = 1,#buffer do
        -- NOTE: buffer is a userdata; must be copied into array
        data[i] = buffer[i]
      end
      return color_goded_buffer_name(), table.concat(data, '\n')
    end
EOF
endfunction!

function! color_goded#setup()
  " Try to get the lua binding working
  lua << EOF
    package.cpath = vim.eval("$VIMHOME") .. "/color_goded.so"
    local loaded = pcall(require, "color_goded")
    if not loaded then
      vim.command('echohl WarningMsg | ' ..
            'echomsg "color_goded unavailable: you need to compile it ' ..
            '(see README.md)" | ' ..
            'echohl None')
      vim.command("let s:color_goded_valid = 0")
      return
    else
      local version = color_goded_api_version()
    end
EOF

  " Lua is prepared, finish setup
  call s:color_goded_create_defaults()
  call s:color_goded_define_lua_helpers()

  return s:color_goded_valid
endfunction!

" Events
" ------------------------------------------------------------------------------

function! color_goded#push()
  if index(g:color_goded_filetypes, &ft) < 0 || g:color_goded_enabled == 0
    return
  endif
lua << EOF
  local name, data = color_goded_buffer_details()
  color_goded_push(name, vim.eval('&ft'), data)
EOF
endfunction!

function! color_goded#pull()
  if index(g:color_goded_filetypes, &ft) < 0 || g:color_goded_enabled == 0
    return
  endif
lua << EOF
  local name = color_goded_buffer_name()
  color_goded_pull(name)
EOF
endfunction!

function! color_goded#moved()
  if index(g:color_goded_filetypes, &ft) < 0 || g:color_goded_enabled == 0
    return
  endif
lua << EOF
  local name = color_goded_buffer_name()
  color_goded_moved(name, vim.eval("line(\"w0\")"), vim.eval("line(\"w$\")"))
EOF
endfunction!

function! color_goded#enter()
  if index(g:color_goded_filetypes, &ft) < 0 || g:color_goded_enabled == 0
    return
  endif

  " Each new window controls highlighting separate from the buffer
  if !exists("w:color_goded_own_syntax") || w:color_goded_name != color_goded#get_buffer_name()
    " Preserve spell after ownsyntax clears it
    let s:keepspell = &spell
      if has('b:current_syntax')
        execute 'ownsyntax ' . b:current_syntax
      else
        execute 'ownsyntax ' . &ft
      endif
      let &spell = s:keepspell
    unlet s:keepspell

    let w:color_goded_own_syntax = 1

    " Each window has a unique ID
    let w:color_goded_unique_counter = s:color_goded_unique_counter
    let s:color_goded_unique_counter += 1

    " Windows can be reused; clear it out if needed
    if exists("w:color_goded_name")
      call color_goded#clear_matches(w:color_goded_name)
    endif
    let w:color_goded_name = color_goded#get_buffer_name()
    call color_goded#clear_matches(w:color_goded_name)
  endif

lua << EOF
  local name, data = color_goded_buffer_details()
  color_goded_enter(name, vim.eval('&ft'), data)
EOF
endfunction!

function! color_goded#destroy()
  if index(g:color_goded_filetypes, &ft) < 0 || g:color_goded_enabled == 0
    return
  endif
lua << EOF
  color_goded_destroy(color_goded_buffer_name())
EOF

  call color_goded#clear_matches(color_goded#get_buffer_name())
endfunction!

function! color_goded#exit()
  if g:color_goded_enabled == 0
    return
  endif
lua << EOF
  color_goded_exit()
EOF
endfunction!

" Commands
" ------------------------------------------------------------------------------

function! color_goded#last_error()
lua << EOF
  vim.command(
    "echo \"" .. string.gsub(color_goded_last_error(), "\"", "'") ..  "\""
  )
EOF
endfunction!

function! color_goded#toggle()
  let g:color_goded_enabled = g:color_goded_enabled ? 0 : 1
  if g:color_goded_enabled == 0
    call color_goded#clear_all_matches()
    echo "color_goded: disabled"
  else
    call color_goded#enter()
    echo "color_goded: enabled"
  endif
endfunction!

" Utilities
" ------------------------------------------------------------------------------

" We keep two sets of buffer names right now
" 1) Lua's color_goded_buffer_name
"   - Just the filename or buffer number
"   - Used for interfacing with C++
" 2) VimL's color_goded#get_buffer_name
"   - A combination of 1) and a unique window counter
"   - Used for storing per-window syntax matches
function! color_goded#get_buffer_name()
lua << EOF
  local name = color_goded_buffer_name()
  vim.command("let s:file = '" .. name .. "'")
EOF
  if exists("w:color_goded_unique_counter")
    return s:file . w:color_goded_unique_counter
  else
    return s:file
  endif
endfunction!

function! color_goded#add_match(type, line, col, len)
  let s:file = color_goded#get_buffer_name()
  call add(g:color_goded_matches[s:file],
          \matchaddpos(a:type, [[ a:line, a:col, a:len ]], -1))
  unlet s:file
endfunction!

" Clears color_goded matches only in the current buffer
function! color_goded#clear_matches(file)
  try
    if has_key(g:color_goded_matches, a:file) == 1
      for id in g:color_goded_matches[a:file]
        call matchdelete(id)
      endfor
    endif
  catch
    echomsg "color_goded caught: " . v:exception
  finally
    let g:color_goded_matches[a:file] = []
  endtry
endfunction!

" Clears color_goded matches in all open buffers
function! color_goded#clear_all_matches()
  let g:color_goded_matches = {}
endfunction!
