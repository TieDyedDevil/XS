project('xs', ['cpp'])
  compiler = meson.get_compiler('cpp')
  compile_flags = ['-I../src', '-Wall', '-Wextra']
  link_flags = []
  boost_dep = dependency('boost')
  ffi_lib = compiler.find_library('ffi')
  gc_lib = compiler.find_library('gc')
  readline_lib = compiler.find_library('readline')
  custom_target('.stamp',
	build_always: true,
	output: '.stamp',
	command: ['touch', '@OUTPUT@'])
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
		'src/version.cxx']
  common_dependencies = [boost_dep, readline_lib, gc_lib, ffi_lib]
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
  install_data(['doc/AUTHORS', 'doc/CHANGES', 'doc/COPYING', 'doc/GOTCHAS',
		'INSTALL', 'doc/NOTES', 'doc/PHILOSOPHY', 'doc/PROJECTS',
		'README', 'doc/SYSTEMD_LOCALE', 'doc/TODO', 'doc/TUTORIAL.md',
		'doc/XS-FOR-LISPERS'],
	install_dir: 'share/doc/xs')
  install_data(['samples/_config/herbstluftwm/autostart',
		'samples/_config/herbstluftwm/panel.xs'],
	install_dir: 'share/doc/xs/samples/_config/herbstluftwm')
  install_data(['samples/_xslib.d/attr.xs', 'samples/_xslib.d/subs.xs',
		'samples/_xslib.d/util.xs'],
	install_dir: 'share/doc/xs/samples/_xslib.d')
  install_data(['samples/_xsrc.d/aliases.xs', 'samples/_xsrc.d/annotate.xs',
		'samples/_xsrc.d/commands.xs', 'samples/_xsrc.d/console.xs',
		'samples/_xsrc.d/env.xs', 'samples/_xsrc.d/help.xs',
		'samples/_xsrc.d/herbstluftwm.xs', 'samples/_xsrc.d/media.xs',
		'samples/_xsrc.d/prompt.xs', 'samples/_xsrc.d/web.xs'],
	install_dir: 'share/doc/xs/samples/_xsrc.d')
  install_data(['samples/_xsuser.d/prompt-config.xs'],
	install_dir: 'share/doc/xs/samples/_xsuser.d')
  install_data(['samples/_xsin', 'samples/_xsrc', 'samples/colors',
		'samples/histclean', 'samples/lock', 'samples/sv',
		'samples/tsm', 'samples/web-browser', 'samples/README'],
	install_dir: 'share/doc/xs/samples')

run_target('check',
	command: ['./build/xs', '-c', './tests/xs_tests.xs'],
	depends: xs)

run_target('fuzz',
	command: ['./build/xs', '-c', './tests/fuzz.xs'],
	depends: xs)
