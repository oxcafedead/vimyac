let g:yac_exec_args = []

function! YacExec(wholeFile, ...)
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

		" Add custom arguments
		if !empty(a:000)
			let l:cmd = l:cmd . ' ' . join(a:000)
		endif

		let l:output = system(l:cmd)

		rightbelow vnew
		setlocal buftype=nofile
		setlocal bufhidden=hide
		setlocal noswapfile
		call setline(1, split(l:output, '\n'))

		let l:bufname = 'httpYac response'

		if bufexists(l:bufname) && buflisted(l:bufname)
			execute 'bdelete ' . bufnr(l:bufname)
		endif

		setlocal nomodifiable
		setlocal readonly

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
