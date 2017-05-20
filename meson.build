project('xs', 'cpp')
  compiler = meson.get_compiler('cpp')
  if compiler.get_id() == 'clang'
	compile_flags = ['-Wall', '-Wextra']
  else
	compile_flags = []
  endif
  boost_dep = dependency('boost')
  ffi_lib = compiler.find_library('ffi')
  gc_lib = compiler.find_library('gc')
  readline_lib = compiler.find_library('readline')
  custom_target('git_date.hxx',
	build_always: true,
	output: 'git_date.hxx',
	command: ['../generators/git_date.sh'])
  custom_target('git_hash.hxx',
	build_always: true,
	output: 'git_hash.hxx',
	command: ['../generators/git_hash.sh'])
  custom_target('git_url.hxx',
	build_always: true,
	output: 'git_url.hxx',
	command: ['../generators/git_url.sh'])
  parse_cxx = custom_target('parse.cxx',
	output: ['parse.cxx', 'parse.hxx'],
	command: ['../generators/mkparse.sh'])
  sigmsgs_cxx = custom_target('sigmsgs.cxx',
	output: 'sigmsgs.cxx',
	command: ['../generators/mksignal.sh', '@OUTPUT@'])
  common_sources = ['access.cxx', 'closure.cxx', 'conv.cxx', 'eval.cxx',
		'fd.cxx', 'glob.cxx', 'glom.cxx', 'heredoc.cxx', 'input.cxx',
		'list.cxx', 'main.cxx', 'match.cxx', 'opt.cxx', parse_cxx,
		'prim-ctl.cxx', 'prim.cxx', 'prim-etc.cxx', 'prim-io.cxx',
		'prim-rel.cxx', 'prim-sys.cxx', 'print.cxx', 'proc.cxx',
		sigmsgs_cxx, 'signal.cxx', 'split.cxx', 'status.cxx',
		'str.cxx', 'syntax.cxx', 'term.cxx', 'token.cxx', 'tree.cxx',
		'util.cxx', 'var.cxx', 'version.cxx']
  common_dependencies = [boost_dep, readline_lib, gc_lib, ffi_lib]
  xsdump = executable('xsdump', ['dump.cxx', common_sources],
	cpp_args: compile_flags,
	dependencies: common_dependencies)
  initial_cxx = custom_target('initial.cxx',
	input: 'initial.xs',
	output: 'initial.cxx',
	depends: xsdump,
	command: ['../generators/initial.sh', '@INPUT@', '@OUTPUT@'])
  xs = executable('xs', [initial_cxx, common_sources],
	cpp_args: compile_flags,
	dependencies: common_dependencies,
	install: true)
  install_man('xs.1')
  install_data(['AUTHORS', 'CHANGES', 'COPYING', 'GOTCHAS', 'INSTALL',
		'NOTES', 'README', 'SYSTEMD_LOCALE', 'TODO'],
	install_dir: 'share/doc/xs')
  install_data(['samples/_xsrc', 'samples/_xsin', 'samples/colors',
		'samples/histclean'],
	install_dir: 'share/doc/xs/samples')
  install_data(['samples/_xsrc.d/daemons.xs', 'samples/_xsrc.d/env.xs',
		'samples/_xsrc.d/prompt.xs'],
	install_dir: 'share/doc/xs/samples/_xsrc.d')

run_target('trip',
	command: ['sh', '-c', './tests/trip.xs'],
	depends: xs)

run_target('check',
	command: ['sh', '-c', './tests/xs_tests.xs'],
	depends: xs)

run_target('fuzz',
	command: ['sh', '-c', './tests/fuzz.sh'],
	depends: xs)
