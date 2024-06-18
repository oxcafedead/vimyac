function! YacExec( wholeFile, ... )
	let l:line = line('.')
	let l:file = expand('%')
	
	if a:wholeFile
		let l:cmd = 'httpyac ' . l:file . ' -a'
	else
		let l:cmd = 'httpyac ' . l:file . ' -l ' . l:line
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
	
	" Only attempt to remove the buffer if it exists *and* is loaded"
	if bufexists(l:bufname) && buflisted(l:bufname)
		execute 'bdelete ' . bufnr(l:bufname)
	endif
	
	" Set the buffer to not modifiable and readonly
	setlocal nomodifiable
	setlocal readonly
	
	" Automatically set the cursor to the first line
	normal gg
	
	if bufexists(l:bufname) && buflisted(l:bufname)
		execute 'file' l:bufname
	else
		execute 'file' "httpYac\ response"
	endif
	" finally, set http file type
	set filetype=http
endfunction

" Add a command to execute yac including potential custom arguments
command! -nargs=* YacExec call YacExec(0, <q-args>)
command! -nargs=* YacExecAll call YacExec(1, <q-args>)

" Default key bindings
nnoremap <leader>yr :YacExec<CR>
nnoremap <leader>ya :YacExecAll<CR>
