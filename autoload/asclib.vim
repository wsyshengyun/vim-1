"======================================================================
"
" asclib.vim - autoload methods
"
" Created by skywind on 2016/10/28
" Last change: 2016/10/28 00:38:10
"
"======================================================================


"----------------------------------------------------------------------
" window basic
"----------------------------------------------------------------------

" save all window's view
function! asclib#window_saveview()
	function! s:window_view_save()
		let w:asclib_window_view = winsaveview()
	endfunc
	let l:winnr = winnr()
	noautocmd windo call s:window_view_save()
	noautocmd silent! exec ''.l:winnr.'wincmd w'
endfunc

" restore all window's view
function! asclib#window_loadview()
	function! s:window_view_rest()
		if exists('w:asclib_window_view')
			call winrestview(w:asclib_window_view)
			unlet w:asclib_window_view
		endif
	endfunc
	let l:winnr = winnr()
	noautocmd windo call s:window_view_rest()
	noautocmd silent! exec ''.l:winnr.'wincmd w'
endfunc

" unique window id
function! asclib#window_uid(tabnr, winnr)
	let name = 'asclib_window_unique_id'
	let uid = gettabwinvar(a:tabnr, a:winnr, name)
	if type(uid) == 1 && uid == ''
		if !exists('s:asclib_window_unique_index')
			let s:asclib_window_unique_index = 1000
			let s:asclib_window_unique_rewind = 0
			let uid = 1000
			let s:asclib_window_unique_index += 1
		else
			let uid = 0
			if !exists('s:asclib_window_unique_rewind')
				let s:asclib_window_unique_rewind = 0
			endif
			if s:asclib_window_unique_rewind == 0 
				let uid = s:asclib_window_unique_index
				let s:asclib_window_unique_index += 1
				if s:asclib_window_unique_index >= 100000
					let s:asclib_window_unique_rewind = 1
					let s:asclib_window_unique_index = 1000
				endif
			else
				let name = 'asclib_window_unique_id'
				let index = s:asclib_window_unique_index
				let l:count = 0
				while l:count < 100000
					let found = 0
					for l:tabnr in range(1, tabpagenr('$'))
						for l:winnr in range(1, tabpagewinnr(l:tabnr, '$'))
							if gettabwinvar(l:tabnr, l:winnr, name) is index
								let found = 1
								break
							endif
						endfor
						if found != 0
							break
						endif
					endfor
					if found == 0
						let uid = index
					endif
					let index += 1
					if index >= 100000
						let index = 1000
					endif
					let l:count += 1
					if found == 0
						break
					endif
				endwhile
				let s:asclib_window_unique_index = index
			endif
			if uid == 0
				echohl ErrorMsg
				echom "error allocate new window uid"
				echohl NONE
				return -1
			endif
		endif
		call settabwinvar(a:tabnr, a:winnr, name, uid)
	endif
	return uid
endfunc

" unique window id to [tabnr, winnr], [0, 0] for not find
function! asclib#window_find(uid)
	let name = 'asclib_window_unique_id'
	" search current tabpagefirst
	for l:winnr in range(1, winnr('$'))
		if gettabwinvar('%', l:winnr, name) is a:uid
			return [tabpagenr(), l:winnr]
		endif
	endfor
	" search all the tabpages
	for l:tabnr in range(1, tabpagenr('$'))
		for l:winnr in range(1, tabpagewinnr(l:tabnr, '$'))
			if gettabwinvar(l:tabnr, l:winnr, name) is a:uid
				return [l:tabnr, l:winnr]
			endif
		endfor
	endfor
	return [0, 0]
endfunc

" switch to tabwin
function! asclib#window_goto_tabwin(tabnr, winnr)
	if a:tabnr != '' && a:tabnr != '%'
		if tabpagenr() != a:tabnr
			silent! exec "tabn ". a:tabnr
		endif
	endif
	if winnr() != a:winnr
		silent! exec ''.a:winnr.'wincmd w'
	endif
endfunc

" switch to window by uid
function! asclib#window_goto_uid(uid)
	let [l:tabnr, l:winnr] = asclib#window_find(a:uid)
	if l:tabnr == 0 || l:winnr == 0
		return 1
	endif
	call asclib#window_goto_tabwin(l:tabnr, l:winnr)
	return 0
endfunc

" new window and return window uid, zero for error
function! asclib#window_new(position, size, avoid)
	function! s:window_new_action(mode)
		if a:mode == 0
			let w:asclib_window_saveview = winsaveview()
		else
			if exists('w:asclib_window_saveview')
				call winrestview(w:asclib_window_saveview)
				unlet w:asclib_window_saveview
			endif
		endif
	endfunc
	let uid = asclib#window_uid('%', '%')
	let retval = 0
	noautocmd windo call s:window_new_action(0)
	noautocmd call asclib#window_goto_uid(uid)
	if type(a:avoid) == 3
		for i in range(winnr('$'))
			let ok = 1
			let bt = &buftype
			for skip in a:avoid
				if skip == bt
					let ok = 0
					break
				endif
			endfor
			if ok != 0
				break
			endif
			noautocmd wincmd w
		endfor
	endif
	if a:position == 'top' || a:position == '0'
		if a:size <= 0
			leftabove new 
		else
			exec 'leftabove '.a:size.'new'
		endif
	elseif a:position == 'bottom' || a:position == '1'
		if a:size <= 0
			rightbelow new
		else
			exec 'rightbelow '.a:size.'new'
		endif
	elseif a:position == 'left' || a:position == '2'
		if a:size <= 0
			leftabove vnew
		else
			exec 'leftabove '.a:size.'vnew'
		endif
	elseif a:position == 'right' || a:position == '3'
		if a:size <= 0
			rightbelow vnew
		else
			exec 'rightbelow '.a:size.'vnew'
		endif
	else
		rightbelow vnew
	endif
	let retval = asclib#window_uid('%', '%')
	noautocmd windo call s:window_new_action(1)
	if retval > 0
		noautocmd call asclib#window_goto_uid(retval)
	endif
	call asclib#window_goto_uid(uid)
	return retval
endfunc



"----------------------------------------------------------------------
" preview window
"----------------------------------------------------------------------
if !exists('g:asclib#preview_position')
	let g:asclib#preview_position = "right"
endif

if !exists('g:asclib#preview_vsize')
	let g:asclib#preview_vsize = 0
endif

if !exists('g:asclib#preview_size')
	let g:asclib#preview_size = 0
endif


" check preview window is open ?
function! asclib#preview_check()
	for i in range(winnr('$'))
		if getwinvar(i + 1, '&previewwindow', 0)
			return asclib#window_uid('%', i + 1)
		endif
	endfor
	return 0
endfunc


" open preview vertical or horizon
function! asclib#preview_open()
	let pid = asclib#preview_check()
	if pid == 0
		let uid = asclib#window_uid('%', '%')
		let pos = g:asclib#preview_position
		let size = g:asclib#preview_vsize
		if pos == 'top' || pos == 'bottom' || pos == '0' || pos == '1'
			let size = g:asclib#preview_size
		endif
		let avoid = ['quickfix', 'help', 'nofile']
		let pid = asclib#window_new(pos, size, avoid)
		if pid > 0
			noautocmd call asclib#window_goto_uid(pid)
			set previewwindow
		endif
		noautocmd call asclib#window_goto_uid(uid)
	endif
	return pid
endfunc

" close preview window
function! asclib#preview_close()
	silent pclose
endfunc

" echo error message
function! asclib#errmsg(msg)
	echohl ErrorMsg
	echom a:msg
	echohl NONE
endfunc

" echo cmdline message
function! asclib#cmdmsg(content, highlight)
	let saveshow = &showmode
	set noshowmode
    let wincols = &columns
    let allowedheight = &lines/5
    let statusline = (&laststatus==1 && winnr('$')>1) || (&laststatus==2)
    let reqspaces_lastline = (statusline || !&ruler) ? 12 : 29
    let width = len(a:content)
    let limit = wincols - reqspaces_lastline
	let allowedheight = &cmdheight
	let l:content = a:content
	if width + 1 > limit
		let l:content = strpart(l:content, 0, limit - 1)
		let width = len(l:content)
	endif
	if a:highlight != 0
		echohl Type
		echo l:content
		echohl NONE
	else
		echo l:content
	endif
	if saveshow != 0
		set showmode
	endif
endfunc


"----------------------------------------------------------------------
" taglist
"----------------------------------------------------------------------
function! asclib#taglist(pattern)
    let ftags = []
    try
        let ftags = taglist(a:pattern)
    catch /^Vim\%((\a\+)\)\=:E/
        " if error occured, reset tagbsearch option and try again.
        let bak = &tagbsearch
        set notagbsearch
        let ftags = taglist(a:pattern)
        let &tagbsearch = bak
    endtry
    return ftags
endfunc



"----------------------------------------------------------------------
" easy tagname
"----------------------------------------------------------------------
function! asclib#tagfind(tagname)
	let pattern = escape(a:tagname, '[\*~^')
	let result = asclib#taglist("^". pattern . "$")
	if result == []
		if pattern !~ '^\(catch\|if\|for\|while\|switch\)$'
			let result = asclib#taglist('::'. pattern .'$')
		endif
	endif
	return result
endfunc


"----------------------------------------------------------------------
" preview word highlight
"----------------------------------------------------------------------
hi previewWord term=bold ctermbg=green ctermfg=black guibg=green guifg=black


"----------------------------------------------------------------------
" display matched tag in the preview window
"----------------------------------------------------------------------
function! asclib#preview_tag(tagname)
	if &previewwindow
		return 0
	endif
	let uid = asclib#window_uid('%', '%')
	let pid = asclib#preview_check()
	let opt = {"tagname":""}
	let varname = 'asclib_preview_tag_cache'
	let reuse = 0
	let index = 0
	if pid > 0
		let [l:tabnr, l:winnr] = asclib#window_find(pid)
		let saveopt = gettabwinvar(l:tabnr, l:winnr, varname)
		if type(saveopt) == type({})
			let l:tagname = get(saveopt, 'tagname', '')
			if l:tagname == a:tagname
				let opt = saveopt
				let reuse = 1
			endif
		endif
	endif
	if reuse == 0
		let opt.tagname = a:tagname
		let opt.taglist = asclib#tagfind(a:tagname)
		let opt.index = 0
		if len(opt.taglist) > 0 && pid > 0
			call settabwinvar(l:tabnr, l:winnr, varname, opt)
		endif
	else
		let opt.index += 1
		if opt.index >= len(opt.taglist)
			let opt.index = 0
		endif
	endif
	if len(opt.taglist) == 0 
		call asclib#errmsg('E257: asclib: tag not find "'. a:tagname.'"')
		return 1
	endif
	if opt.index >= len(opt.taglist)
		call asclib#errmsg('E257: asclib: index error')
		return 2
	endif
	let taginfo = opt.taglist[opt.index]
	let filename = taginfo.filename
	if !filereadable(filename)
		call asclib#errmsg('E484: Can not open file '.filename)
		return 3
	endif
	if pid == 0
		let pid = asclib#preview_open()
		let [l:tabnr, l:winnr] = asclib#window_find(pid)
	endif
	call settabwinvar(l:tabnr, l:winnr, varname, opt)
	call asclib#window_goto_uid(uid)
	if 0
		let saveview = winsaveview()
		silent exec 'pedit '.fnameescape(filename)
		call winrestview(saveview)
		call asclib#window_goto_tabwin(l:tabnr, l:winnr)
	else
		call asclib#window_saveview()
		call asclib#window_goto_tabwin(l:tabnr, l:winnr)
		silent exec 'e! '.fnameescape(filename)
		call asclib#window_loadview()
	endif
	if &previewwindow
		match none
	endif
	normal! gg
	silent! exec taginfo.cmd
	if has("folding")
		silent! .foldopen!
	endif
	normal! zz
	let height = winheight('%') / 4
	if height >= 2
		silent! exec 'normal! '.height."\<c-e>"
	endif
	if 1
		call search("$", "b")
		call search(escape(a:tagname, '[\*~^'))
		exe 'match previewWord "\%' . line(".") . 'l\%' . col(".") . 'c\k*"'
	endif
	call asclib#window_goto_uid(uid)
	let text = taginfo.name
	let text.= ' ('.(opt.index + 1).'/'.len(opt.taglist).') '
	let text.= filename
	call asclib#cmdmsg(text, 1)
endfunc


"----------------------------------------------------------------------
" display preview file
"----------------------------------------------------------------------
function! asclib#preview_edit(bufnr, filename, line)
	let uid = asclib#window_uid('%', '%')
	let pid = asclib#preview_open()
	let [l:tabnr, l:winnr] = asclib#window_find(pid)
	call asclib#window_goto_tabwin(l:tabnr, l:winnr)
	call asclib#window_saveview()
	if a:bufnr <= 0
		silent exec "e! ".fnameescape(a:filename)
	else
		if winbufnr('%') != a:bufnr
			silent exec "b! ".a:bufnr
		endif
	endif
	call asclib#window_loadview()
	if a:line > 0
		noautocmd exec "".a:line
		if has('folding')
			silent! .foldopen!
		endif
		noautocmd exec "normal! zz"
		let height = winheight('%') / 4
		if height >= 2
			noautocmd exec "normal! ".height."\<c-e>"
		endif
		if &previewwindow
			match none
			exec 'match previewWord "\%'. a:line.'l"'
		endif
	endif
	call asclib#window_goto_uid(uid)
endfunc


"----------------------------------------------------------------------
" goto preview file
"----------------------------------------------------------------------
function! asclib#preview_goto(mode)
	let uid = asclib#window_uid('%', '%')
	let pid = asclib#preview_check()
	if pid == 0 || &previewwindow != 0 || uid == pid
		exec "norm! \<esc>"
		return
	endif
	if index(['quickfix', 'help', 'nofile'], &buftype) >= 0
		if a:mode == '' || a:mode == '0' || a:mode == '!'
			exec "norm! \<esc>"
			return
		endif
	endif
	let [l:tabnr, l:winnr] = asclib#window_find(pid)
	silent! wincmd P
	let l:bufnr = winbufnr(l:winnr)
	let l:bufname = bufname(l:bufnr)
	let l:line = line('.')
	call asclib#window_goto_uid(uid)
	if a:mode == '' || a:mode == '0'
		if l:bufnr != winbufnr('%')
			silent exec 'e '.fnameescape(l:bufname)
		endif
	elseif a:mode == '!'
		if l:bufnr != winbufnr('%')
			silent exec 'e! '.fnameescape(l:bufname)
		endif
	elseif a:mode == 'tab'
		silent exec 'tabe '. fnameescape(l:bufname)
	endif
	if winbufnr('%') == l:bufnr
		silent exec ''.l:line
		silent normal! zz
		let height = winheight('%') / 4
		if height >= 2
			exec "normal! ".height."\<c-e>"
		endif
	endif
endfunc


"----------------------------------------------------------------------
" display quickfix item in preview
"----------------------------------------------------------------------
function! asclib#preview_quickfix(linenr)
	let qflist = getqflist()
	if a:linenr < 1 || a:linenr > len(qflist)
		exec "norm! \<esc>"
		return
	endif
	let entry = qflist[a:linenr - 1]
	unlet qflist
	if entry.valid
		if entry.bufnr > 0
			call asclib#preview_edit(entry.bufnr, '', entry.lnum)
			let text = 'Preview: '.bufname(entry.bufnr)
			let text.= ' ('.entry.lnum.')'
			call asclib#cmdmsg(text, 1)
		else
			exec "norm! \<esc>"
		endif
	else
		exec "norm! \<esc>"
	endif
endfunc


"----------------------------------------------------------------------
" path basic
"----------------------------------------------------------------------
let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h')
let s:windows = (has('win95') || has('win32') || has('win64') || has('win16'))

" join path
function! asclib#path_join(home, name)
    let l:size = strlen(a:home)
    if l:size == 0 | return a:name | endif
    let l:last = strpart(a:home, l:size - 1, 1)
    if has("win32") || has("win64") || has("win16") || has('win95')
        if l:last == "/" || l:last == "\\"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    else
        if l:last == "/"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    endif
endfunc

" path asc home
function! asclib#path_runtime(path)
	let pathname = fnamemodify(s:scripthome, ':h')
	let pathname = asclib#path_join(pathname, a:path)
	let pathname = fnamemodify(pathname, ':p')
	return substitute(pathname, '\\', '/', 'g')
endfunc

" find files in path
function! asclib#path_which(name)
	if has('win32') || has('win64') || has('win16') || has('win95')
		let sep = ';'
	else
		let sep = ':'
	endif
	for path in split($PATH, sep)
		let filename = asclib#path_join(path, a:name)
		if filereadable(filename)
			return vimmake#fullname(filename)
		endif
	endfor
	return ''
endfunc

" find executable
function! asclib#path_executable(name)
	if s:windows != 0
		for n in ['', '.exe', '.cmd', '.bat', '.vbs']
			let nname = a:name . n
			let npath = asclib#path_which(nname)
			if npath != ''
				return npath
			endif
		endfor
	else
		return asclib#path_which(a:name)
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" lint - 
"----------------------------------------------------------------------

" python - pylint
function! asclib#lint_pylint(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path_runtime('tools/conf/pylint.conf') 
	let cmd = 'pylint --rcfile='.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc

" python - flake8
function! asclib#lint_flake8(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path_runtime('tools/conf/flake8.conf') 
	let cmd = 'flake8 --config='.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc

" c/c++ - cppcheck
function! asclib#lint_cppcheck(filename)
	if !exists('g:asclib#lint_cppcheck_parameters')
		let g:asclib#lint_cppcheck_parameters = '--library=windows'
		let g:asclib#lint_cppcheck_parameters.= ' --quiet'
		let g:asclib#lint_cppcheck_parameters.= ' --enable=warning'
		let g:asclib#lint_cppcheck_parameters.= ',performance,portability'
		let g:asclib#lint_cppcheck_parameters.= ' -DWIN32 -D_WIN32'
	endif
	let filename = (a:filename == '')? expand('%') : a:filename
	let cfg = g:asclib#lint_cppcheck_parameters
	let cmd = 'cppcheck '.cfg.' '.shellescape(filename)
	call vimmake#run('', {'auto':'make'}, cmd)
endfunc

" c - splint
function! asclib#lint_splint(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path_runtime('tools/conf/splint.conf') 
	let cmd = 'splint -f '.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc


"----------------------------------------------------------------------
" open something
"----------------------------------------------------------------------

" call winhlp32.exe to open .hlp
function! asclib#open_win32_help(hlp, keyword)
	if !filereadable(a:hlp)
		call asclib#errmsg('can not open: '.a:hlp)
		return 1
	endif
	if asclib#path_which('winhlp32.exe') == ''
		call asclib#errmsg('can not find WinHlp32.exe, please install it')
		return 2
	endif
	let cmd = 'WinHlp32.exe '
	if a:keyword
		let cmd .= '-k '.shellescape(a:keyword). ' '
	endif
	silent exec 'VimMake -mode=5 '.cmd. shellescape(a:hlp)
	return 0
endfunc


function! asclib#open_win32_chm(chm, keyword)
	if !filereadable(a:chm)
		call asclib#errmsg('can not open: '.a:chm)
		return 1
	endif
	if !a:keyword
		silent exec 'VimMake -mode=5 '.shellescape(a:chm)
		return 0
	else
		if asclib#path_which('KeyHH.exe') == ''
			call asclib#errmsg('can not find KeyHH.exe, please install it')
			return 2
		endif
	endif
	let cmd = 'KeyHH.exe -MyHelp -#klink '.shellescape(a:keyword).' '.a:chm
endfunc


"----------------------------------------------------------------------
" smooth interface
"----------------------------------------------------------------------
function! s:smooth_scroll(dir, dist, duration, speed)
	for i in range(a:dist/a:speed)
		let start = reltime()
		if a:dir ==# 'd'
			exec 'normal! '. a:speed."\<C-e>".a:speed."j"
		else
			exec 'normal! '. a:speed."\<C-y>".a:speed."k"
		endif
		redraw
		let elapsed = s:get_ms_since(start)
		let snooze = float2nr(a:duration - elapsed)
		if snooze > 0
			exec "sleep ".snooze."m"
		endif
	endfor
endfunc

function! s:get_ms_since(time)
	let cost = split(reltimestr(reltime(a:time)), '\.')
	return str2nr(cost[0]) * 1000 + str2nr(cost[1]) / 1000.0
endfunc

function! asclib#smooth_scroll_up(dist, duration, speed)
	call s:smooth_scroll('u', a:dist, a:duration, a:speed)
endfunc

function! asclib#smooth_scroll_down(dist, duration, speed)
	call s:smooth_scroll('d', a:dist, a:duration, a:speed)
endfunc


"----------------------------------------------------------------------
" gprof
"----------------------------------------------------------------------
function! asclib#open_gprof(image, profile)
	let l:image = a:image
	let l:profile = a:profile
	if asclib#path_executable('gprof') == ''
		call s:errmsg('cannot find gprof')
		return
	endif
	if l:image == ''
		let l:image = expand("%:p:h") . '/' . expand("%:t:r") 
		let l:image.= s:windows? '.exe' : ''
		if l:profile == ''
			let l:profile = expand("%:p:h") . '/gmon.out'
		endif
	elseif l:profile == ''
		let l:profile = 'gmon.out'
	endif
	let command = 'gprof '.shellescape(l:image).' '.shellescape(l:profile)
	let text = vimmake#python_system(command)
	let text = substitute(text, '\r', '', 'g')
	vnew
	let l:save = @0
	let @0 = text
	normal! "0P
	let @0 = l:save
    setlocal noshowcmd
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nobuflisted
    setlocal nomodifiable
    setlocal nowrap
    setlocal nonumber
	setlocal readonly
	setlocal filetype=gprof
endfunc




