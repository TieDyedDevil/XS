project('xs', ['cpp'])
  compiler = meson.get_compiler('cpp')
  compile_flags = ['-I../src', '-Wall', '-Wextra']
  link_flags = []
  boost_dep = dependency('boost', version: '>=1.60')
  ffi_lib = dependency('ffi', version: '>=6.0.2', required: false)
  if not ffi_lib.found()
    ffi_lib = compiler.find_library('ffi')
  endif
  gc_lib = dependency('gc', version: '>=1.0.3', required: false)
  if not gc_lib.found()
    gc_lib = compiler.find_library('gc')
  endif
  gccpp_lib = compiler.find_library('gccpp')
  readline_lib = dependency('readline', version: '>=6.3', required: false)
  if not readline_lib.found()
    readline_lib = compiler.find_library('readline')
  endif
  custom_target('.stamp',
	build_always_stale: true,
	build_by_default: true,
	output: '.stamp',
	command: ['touch', '@OUTPUT@'])
  custom_target('buildinfo.hxx',
	build_always_stale: true,
	build_by_default: true,
	output: 'buildinfo.hxx',
	command: ['../generators/buildinfo.sh'])
  custom_target('git_date.hxx',
	build_always_stale: true,
	build_by_default: true,
	output: 'git_date.hxx',
	command: ['../generators/git_date.sh'])
  custom_target('git_hash.hxx',
	build_always_stale: true,
	build_by_default: true,
	output: 'git_hash.hxx',
	command: ['../generators/git_hash.sh'])
  custom_target('git_url.hxx',
	build_always_stale: true,
	build_by_default: true,
	output: 'git_url.hxx',
	command: ['../generators/git_url.sh'])
  parse_cxx = custom_target('parse.cxx',
	depend_files: 'src/parse.yxx',
	input: ['src/parse.yxx'],
	output: ['parse.tab.cxx', 'parse.tab.hxx'],
	command: ['bison', '-d', '@INPUT@'])
  sigmsgs_cxx = custom_target('sigmsgs.cxx',
	output: 'sigmsgs.cxx',
	command: ['../generators/mksignal.sh', '@OUTPUT@'])
  common_sources = ['src/access.cxx', 'src/closure.cxx', 'src/conv.cxx',
		'src/eval.cxx', 'src/fd.cxx', 'src/glob.cxx', 'src/glom.cxx',
		'src/heredoc.cxx', 'src/input.cxx', 'src/list.cxx',
		'src/main.cxx', 'src/match.cxx', 'src/opt.cxx', parse_cxx,
		'src/prim-ctl.cxx', 'src/prim.cxx', 'src/prim-etc.cxx',
		'src/prim-io.cxx', 'src/prim-rel.cxx', 'src/prim-sys.cxx',
		'src/print.cxx', 'src/proc.cxx', sigmsgs_cxx, 'src/signal.cxx',
		'src/split.cxx', 'src/status.cxx', 'src/str.cxx',
		'src/syntax.cxx', 'src/term.cxx', 'src/token.cxx',
		'src/tree.cxx', 'src/util.cxx', 'src/var.cxx',
		'src/version.cxx', 'src/buildinfo.cxx']
  common_dependencies = [boost_dep, readline_lib, gc_lib, gccpp_lib, ffi_lib]
  xsdump = executable('xsdump', ['src/dump.cxx', common_sources],
	cpp_args: compile_flags,
	dependencies: common_dependencies)
  initial_cxx = custom_target('initial.cxx',
	input: 'src/initial.xs',
	output: 'initial.cxx',
	depends: xsdump,
	command: ['../generators/initial.sh', '@INPUT@', '@OUTPUT@'])
  xs = executable('xs', [initial_cxx, common_sources],
	cpp_args: compile_flags,
	link_args: link_flags,
	dependencies: common_dependencies,
	install: true)
  install_man(['man/xs.1'])
  install_data(['doc/ANCESTORS', 'doc/CHANGES', 'doc/COPYING',
		'INSTALL', 'doc/PHILOSOPHY', 'doc/PROJECTS', 'README.md',
		'doc/SYSTEMD_LOCALE', 'doc/TODO', 'doc/TUTORIAL.md',
		'doc/XS-FOR-LISPERS.md', 'xs.lang'],
	install_dir: 'share/doc/xs')

run_target('check',
	command: ['./build/xs', '-c', './tests/xs_tests.xs'],
	depends: xs)

run_target('fuzz',
	command: ['./build/xs', '-c', './tests/fuzz.xs'],
	depends: xs)
