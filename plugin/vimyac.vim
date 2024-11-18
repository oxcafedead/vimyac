let g:yac_exec_args = []
let g:yac_environments_per_project = {}

function! YacSetProjectEnv(env)
	let l:project_root = YacProjectRoot()
	if empty(l:project_root)
		let l:project_root = '_DEFAULT_'
	endif
	let g:yac_environments_per_project[l:project_root] = a:env
endfunction

function! YacGetProjectEnv()
	let l:project_root = YacProjectRoot()
	if empty(l:project_root)
		let l:project_root = '_DEFAULT_'
	endif
	return get(g:yac_environments_per_project, l:project_root, '')
endfunction

function! YacProjectRoot()
	let l:dir = fnamemodify(expand('%'), ':p:h')
	while l:dir != '/'
		if filereadable(l:dir . '/package.json') || filereadable(l:dir . '/httpyac.config.js') || filereadable(l:dir . '/.httpyac.js') || filereadable(l:dir . '/.httpyac.json') || isdirectory(l:dir . '/env')
			return l:dir
		endif
		let l:dir = fnamemodify(l:dir, ':p:h:h')
	endwhile
	return ''
endfunction

function! YacEnvCandidates()
	let l:dir = fnamemodify(expand('%'), ':p:h')
	let l:project_root = YacProjectRoot()
	let l:candidates = [l:dir]
	if !empty(l:project_root) && index(l:candidates, l:project_root) == -1
		call add(l:candidates, l:project_root)
	endif
	call add(l:candidates, l:project_root . '/env')
	if !empty($HTTPYAC_ENV)
		call add(l:candidates, $HTTPYAC_ENV)
	endif
	let l:env_files = []
	for l:candidate in l:candidates
		let l:files = systemlist('find ' . candidate . ' -maxdepth 1 -name "*.env*"')
		for l:file in l:files
			if l:file =~ '.*\.env\(\..*\)\?$'
				call add(l:env_files, l:file)
			endif
		endfor
	endfor
	return l:env_files
endfunction

function! YacChooseEnv()
	let l:env_files = YacEnvCandidates()
	if empty(l:env_files)
		return ''
	endif
	if len(l:env_files) == 1
		call YacSetProjectEnv(l:env_files[0])
		return l:env_files[0]
	endif
	let l:labels = []
	let l:option_number = 1
	for l:env_file in l:env_files
		let l:only_file_name = fnamemodify(l:env_file, ':t')
		call add(l:labels, l:option_number . '. ' . l:only_file_name)
		let l:option_number = l:option_number + 1
	endfor
	let l:ret = inputlist(['Select env file:'] + l:labels)
	if l:ret == -1
		return ''
	endif
	let l:env_file = l:env_files[l:ret - 1]
	call YacSetProjectEnv(l:env_file)
	return l:env_file
endfunction

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
		let l:project_root = YacProjectRoot()
		let l:existing_env = YacGetProjectEnv()
		if empty(l:existing_env)
			let l:env_file = YacChooseEnv()
			if !empty(l:env_file)
				" httpyac only understands env name itself
				" (with no extension) not the full path
				" so we need to extract it
				let l:env_name = fnamemodify(l:env_file, ':t:r')
				let l:cmd = l:cmd . ' -e ' . l:env_name
			endif
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
