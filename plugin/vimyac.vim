let g:yac_exec_args = []

" The function parses raw output and creates list of outputs with no extra
" data to put into separate buffers with a proper HTTP syntax highlighting
function! YacNormalize(content)
	let l:split_seq = '---------------------'
	let l:lines = split(a:content, '\n')
	let l:normalized = ''
	let l:current_request = ''
	let l:new_line = '\n'
	for l:line in l:lines
		if l:line == l:split_seq
			let l:normalized = l:normalized . l:current_request . l:new_line
			let l:current_request = '###'.l:new_line
		else
			if l:line =~ '^=== .* ==='
				" this is kind of request info, so we can
				" insert it as ### Request info ###
				" as a part of normalized output
				let l:comment = substitute(l:line, '^=== \(.*\) ===', '\1', '')
				let l:current_request = '### '. l:comment . ' ###' . l:new_line
				continue
			endif
			let l:current_request = l:current_request . l:line . l:new_line
		endif
	endfor
	let l:normalized = l:normalized . l:current_request
	return l:normalized
endfunction

function! YacExec(wholeFile, ...)
	if !executable('httpyac')
		echoerr 'httpyac is not installed. Please install it first (see h: vimyac-requirements)'
		return
	endif

	let l:line = line('.')
	let l:file = expand('%')
	let l:dir = fnamemodify(l:file, ':p:h')
	let l:tmpfile = l:dir . '/.tmp_yac_request~'

	call writefile(getline(1, '$'), l:tmpfile)

	try
		if a:wholeFile
			let l:cmd = 'httpyac ' . l:tmpfile . ' -a'
		else
			let l:cmd = 'httpyac ' . l:tmpfile . ' -l ' . l:line
		endif

		if !empty(a:000)
			let l:cmd = l:cmd . ' ' . join(a:000)
		endif

		let l:output = YacNormalize(system(l:cmd))

		rightbelow vnew
		setlocal buftype=nofile
		setlocal bufhidden=hide
		setlocal noswapfile
		let l:content_for_buf = split(l:output, '\\n')
		call append(0, l:content_for_buf)

		let l:bufname = 'httpYac response'

		if bufexists(l:bufname) && buflisted(l:bufname)
			execute 'bdelete ' . bufnr(l:bufname)
		endif

		normal gg
		execute 'file' l:bufname
		set filetype=http
	finally
		if filereadable(l:tmpfile)
			call delete(l:tmpfile)
		endif
	endtry
endfunction

function! YacExecArgs(A, L, P)
	if empty(g:yac_exec_args)
		" only send options since plugin essentially only runs send
		" command
		let l:help_output = system('httpyac send --help')
		let l:lines = split(l:help_output, '\n')
		let g:yac_exec_args = []
		for l:line in l:lines
			let l:parts = split(l:line)
			for l:part in l:parts
				if l:part =~ '^-'
					" trim commas and equal signs
					let l:part = substitute(l:part, '[=,]', '', 'g')
					call add(g:yac_exec_args, l:part)
				endif
			endfor
		endfor
	endif
	" now, only return matching options
	let l:matches = []
	for l:arg in g:yac_exec_args
		if l:arg =~ a:A
			call add(l:matches, l:arg)
		endif
	endfor
	return l:matches
endfunction

command! -nargs=* -complete=customlist,YacExecArgs YacExec call YacExec(0, <f-args>)
command! -nargs=* -complete=customlist,YacExecArgs YacExecAll call YacExec(1, <f-args>)

" Default key bindings
nnoremap <leader>yr :YacExec<CR>
nnoremap <leader>ya :YacExecAll<CR>
