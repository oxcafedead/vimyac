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
		if a:0 > 0
			let l:cmd = l:cmd . ' ' . a:1
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

" Add a command to execute yac including potential custom arguments
command! -nargs=* YacExec call YacExec(0, <q-args>)
command! -nargs=* YacExecAll call YacExec(1, <q-args>)

" Default key bindings
nnoremap <leader>yr :YacExec<CR>
nnoremap <leader>ya :YacExecAll<CR>
