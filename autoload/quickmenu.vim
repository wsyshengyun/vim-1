"======================================================================
"
" quickmenu.vim - 
"
" Created by skywind on 2017/07/08
" Last change: 2017/07/08 23:18:45
"
"======================================================================


"----------------------------------------------------------------------
" Global Options
"----------------------------------------------------------------------
if !exists('g:quickmenu_max_width')
	let g:quickmenu_max_width = 40
endif

if !exists('g:quickmenu_min_width')
	let g:quickmenu_min_width = 15
endif

if !exists('g:quickmenu_disable_nofile')
	let g:quickmenu_disable_nofile = 1
endif

if !exists('g:quickmenu_ft_blacklist')
	let g:quickmenu_ft_blacklist = ['netrw', 'nerdtree']
endif

if !exists('g:quickmenu_padding_left')
	let g:quickmenu_padding_left = '  '
endif


"----------------------------------------------------------------------
" Internal State
"----------------------------------------------------------------------
let s:quickmenu_items = []
let s:quickmenu_name = '[quickmenu]'
let s:quickmenu_last = 0


"----------------------------------------------------------------------
" popup window management
"----------------------------------------------------------------------
function! s:window_exist()
	if !exists('t:quickmenu_bid')
		let t:quickmenu_bid = -1
		return 0
	endif
	return t:quickmenu_bid > 0 && bufexists(t:quickmenu_bid)
endfunc

function! s:window_close()
	if !exists('t:quickmenu_bid')
		return 0
	endif
	if t:quickmenu_bid > 0 && bufexists(t:quickmenu_bid)
		exec 'bwipeout ' . t:quickmenu_bid
		let t:quickmenu_bid = -1
	endif
endfunc

function! s:window_open(size)
	if s:window_exist()
		call s:window_close()
	endif
	let size = a:size
	let size = (size < g:quickmenu_min_width)? g:quickmenu_min_width : size
	let size = (size > g:quickmenu_max_width)? g:quickmenu_max_width : size
	let savebid = bufnr('%')
	exec "silent! ".size.'vne '.s:quickmenu_name
	if savebid == bufnr('%')
		return 0
	endif
	setlocal buftype=nofile bufhidden=wipe nobuflisted nomodifiable
	setlocal noshowcmd noswapfile nowrap nonumber signcolumn=no nospell
	setlocal fdc=0 nolist colorcolumn= nocursorline nocursorcolumn
	setlocal noswapfile norelativenumber
	let t:quickmenu_bid = bufnr('%')
	return 1
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------

function! quickmenu#reset()
	let s:quickmenu_items = []
	let s:quickmenu_last = 0
endfunc

function! quickmenu#append(text, event, ...)
	let filetype = (a:0 >= 1)? a:1 : ''
	let weight = (a:0 >= 2)? a:2 : 0
	let item = {}
	let item.mode = 0
	let item.event = a:event
	let item.text = a:text
	let item.key = ''
	let item.ft = []
	let item.weight = weight
	if a:event != ''
		let item.mode = 0
	elseif a:text[0] != '#'
		let item.mode = 1
	else
		let item.mode = 2
		let item.text = matchstr(a:text, '^#\+\s*\zs.*')
	endif
	for ft in split(filetype, ',')
		let item.ft += [substitute(ft, '^\s*\(.\{-}\)\s*$', '\1', '')]
	endfor
	let index = -1
	let total = len(s:quickmenu_items)
	for i in range(0, total - 1)
		if weight < s:quickmenu_items[i].weight
			let index = i
			break
		endif
	endfor
	if index < 0
		let index = total
	endif
	call insert(s:quickmenu_items, item, index)
	return index
endfunc

function! quickmenu#list()
	for item in s:quickmenu_items
		echo item
	endfor
endfunc




"----------------------------------------------------------------------
" quickmenu interface
"----------------------------------------------------------------------

function! quickmenu#toggle(bang) abort
	if s:window_exist()
		call s:window_close()
		return 0
	endif
	if g:quickmenu_disable_nofile
		if &buftype == 'nofile' || &buftype == 'quickfix'
			return 0
		endif
		if &modifiable == 0
			if index(g:quickmenu_ft_blacklist, &ft) >= 0
				return 0
			endif
		endif
	endif

	" arrange menu
	let items = s:select_by_ft(&ft)
	let content = []
	let maxsize = 8
	let lastmode = 2

	" calculate max width
	for item in items
		let hr = s:menu_expand(item)
		for outline in hr
			let text = outline['text']
			if strlen(text) > maxsize
				let maxsize = strlen(text)
			endif
		endfor
		let content += hr
	endfor
	
	let maxsize += len(g:quickmenu_padding_left)

	if 1
		call s:window_open(maxsize)
		call s:window_render(content)
		call s:setup_keymaps(content)
	else
		for item in content
			echo item
		endfor
		return 0
	endif

	return 1
endfunc



"----------------------------------------------------------------------
" render text
"----------------------------------------------------------------------
function! s:window_render(items)
	setlocal modifiable
	let ln = 2
	for item in a:items
		let item.ln = ln
		let ln += 1
		call append('$', item.text)
	endfor
	setlocal nomodifiable readonly
endfunc


"----------------------------------------------------------------------
" all keys 
"----------------------------------------------------------------------
function! s:setup_keymaps(items)
endfunc


"----------------------------------------------------------------------
" select items by &ft, generate keymap and add some default items
"----------------------------------------------------------------------
function! s:select_by_ft(ft)
	let hint = '123456789abcdefhlmnopqrstuvwxyz*'
	let items = []
	let index = 0
	let lastmode = 2
	for item in s:quickmenu_items
		if len(item.ft) && index(item.ft, a:ft) >= 0
			continue
		endif
		if item.mode == 2 && lastmode != 2 
			" insert empty line
			let ni = {'mode':1, 'text':'', 'event':''}
			let items += [ni]
		endif
		let lastmode = item.mode
		if item.mode == 0
			let item.key = hint[index]
			let index += 1
			if index >= strlen(hint)
				let index = strlen(hint) - 1
			endif
		endif
		let items += [item]
		if item.mode == 2 
			" insert empty line
			let ni = {'mode':1, 'text':'', 'event':''}
			let items += [ni]
		endif
	endfor
	if len(items)
		let item = {'mode':1, 'text':'', 'event':''}
		let items += [item]
	endif
	let item = {}
	let item.mode = 0
	let item.text = '<close>'
	let item.event = 'close'
	let item.key = '0'
	let items += [item]
	return items
endfunc


"----------------------------------------------------------------------
" expand menu items
"----------------------------------------------------------------------
function! s:menu_expand(item) abort
	let items = []
	let text = s:expand_text(a:item.text)
	let index = 0
	for curline in split(text, "\n", 1)
		let item = {}
		let item.mode = a:item.mode
		let item.text = curline
		let item.event = ''
		let item.key = ''
		if item.mode == 0
			if index == 0
				let item.text = '[' . a:item.key.']  '.curline
				let index += 1
				let item.key = a:item.key
				let item.event = a:item.event
			else
				let item.text = '     '.curline
			endif
		endif
		if len(item.text)
			let item.text = g:quickmenu_padding_left . item.text
		endif
		let items += [item]
	endfor
	return items
endfunc


"----------------------------------------------------------------------
" eval & expand: '%{script}' in string
"----------------------------------------------------------------------
function! s:expand_text(string) abort
	let partial = []
	let index = 0
	while 1
		let pos = stridx(a:string, '%{', index)
		if pos < 0
			let partial += [a:string[index:]]
			break
		endif
		let head = ''
		if pos > index
			let partial += [a:string[index:pos - 1]]
		endif
		let endup = stridx(a:string, '}', pos + 2)
		if endup < 0
			let partial += [a:string[index:]]
			break
		endif
		let index = endup + 1
		if endup > pos + 2
			let script = a:string[pos + 2:endup - 1]
			let script = substitute(script, '^\s*\(.\{-}\)\s*$', '\1', '')
			let result = eval(script)
			let partial += [result]
		endif
	endwhile
	return join(partial, '')
endfunc



"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------

if 1
	call quickmenu#append('# Start', '')
	call quickmenu#append('test1', 'echo 1')
	call quickmenu#append('test2', 'echo 2')

	call quickmenu#append('# Misc', '')
	call quickmenu#append('test2', '')
	call quickmenu#toggle(0)
endif


