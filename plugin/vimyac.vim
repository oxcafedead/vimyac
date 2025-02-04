let g:yac_exec_args = []
let g:yac_environments_per_project = {}

function! YacSetProjectEnv(env)
	let l:project_root = YacProjectRoot()
	if empty(l:project_root)
		let l:project_root = '_DEFAULT_'
	endif
	if empty(a:env)
		let g:yac_environments_per_project[l:project_root] = '(default)'
	else
		let g:yac_environments_per_project[l:project_root] = a:env
	endif
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
	let l:env_names = []
	for l:candidate in l:candidates
		let l:files = systemlist('find ' . candidate . ' -maxdepth 1 -name "*.env*"')
		for l:file in l:files
			let l:file = fnamemodify(l:file, ':t')
			if l:file =~ '^\.env$'
				call add(l:env_names, '')
			elseif l:file =~ '\.env\..*'
				" env name is myenv if file name is .env.myenv
				let l:env_name = substitute(l:file, '.env.', '', '')
				call add(l:env_names, l:env_name)
			elseif l:file =~ '.*\.env$'
				" env name is myenv if file name is myenv.env
				let l:env_name = substitute(l:file, '.env$', '', '')
				call add(l:env_names, l:env_name)
			endif
		endfor
	endfor
	let l:normalized = []
	for l:env_name in l:env_names
		if index(l:normalized, l:env_name) == -1
			call add(l:normalized, l:env_name)
		endif
	endfor
	return sort(l:normalized)
endfunction

function! YacChooseEnv()
	let l:env_names = YacEnvCandidates()
	if empty(l:env_names)
		return ''
	endif
	if len(l:env_names) == 1
		call YacSetProjectEnv(l:env_names[0])
		return l:env_names[0]
	endif
	let l:labels = []
	let l:option_number = 1
	for l:env_name in l:env_names
		if empty(l:env_name)
			call add(l:labels, l:option_number . '. (default)')
		else
			call add(l:labels, l:option_number . '. ' . l:env_name)
		endif
		let l:option_number = l:option_number + 1
	endfor
	let l:ret = inputlist(['Select environment:'] + l:labels)
	if l:ret == -1
		return ''
	endif
	let l:env_name = l:env_names[l:ret - 1]
	call YacSetProjectEnv(l:env_name)
	return l:env_name
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
	let l:cwd = getcwd()
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
		let l:env_name = YacGetProjectEnv()
		if empty(l:env_name)
			let l:env_name = YacChooseEnv()
		endif
		if !empty(l:env_name) && l:env_name != '(default)'
			let l:cmd = l:cmd . ' -e ' . l:env_name
		endif

		if !empty(a:000)
			let l:cmd = l:cmd . ' ' . join(a:000)
		endif

		if !empty(l:project_root)
			execute 'cd ' . l:project_root
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
		execute 'cd ' . l:cwd
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
command! YacChooseEnv call YacChooseEnv()

" Default key bindings
nnoremap <leader>yr :YacExec<CR>
nnoremap <leader>ya :YacExecAll<CR>
