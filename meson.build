project('xs', ['cpp', 'c'])
  compiler = meson.get_compiler('cpp')
  if compiler.get_id() == 'clang'
	compile_flags = ['-Wall', '-Wextra', '-O3']
	link_flags = ['-Wl,-s']
  else
	compile_flags = []
	link_flags = []
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
	link_args: link_flags,
	dependencies: common_dependencies,
	install: true)
  xs_pprint = executable('xs_pprint', ['xs_pprint.c'],
	cpp_args: compile_flags,
	install: true)
  install_man(['xs.1', 'xs_pprint.1'])
  install_data(['AUTHORS', 'CHANGES', 'COPYING', 'GOTCHAS', 'INSTALL',
		'NOTES', 'README', 'SYSTEMD_LOCALE', 'TODO', 'TUTORIAL.md'],
	install_dir: 'share/doc/xs')
  install_data(['samples/_xsrc', 'samples/_xsin', 'samples/colors',
		'samples/histclean'],
	install_dir: 'share/doc/xs/samples')
  install_data(['samples/_xsrc.d/aliases.xs', 'samples/_xsrc.d/commands.xs',
		'samples/_xsrc.d/console.xs', 'samples/_xsrc.d/env.xs',
		'samples/_xsrc.d/help.xs', 'samples/_xsrc.d/mame-games.xs',
		'samples/_xsrc.d/media.xs', 'samples/_xsrc.d/prompt-config.xs',
		'samples/_xsrc.d/prompt.xs', 'samples/_xsrc.d/web.xs'],
	install_dir: 'share/doc/xs/samples/_xsrc.d')
  install_data(['samples/_xslib.d/attr.xs', 'samples/_xslib.d/subs.xs',
		'samples/_xslib.d/util.xs'],
	install_dir: 'share/doc/xs/samples/_xslib.d')

run_target('trip',
	command: ['sh', '-c', './tests/trip.xs'],
	depends: xs)

run_target('check',
	command: ['sh', '-c', './tests/xs_tests.xs'],
	depends: xs)

run_target('fuzz',
	command: ['sh', '-c', './tests/fuzz.sh'],
	depends: xs)
