libvfn = dependency('libvfn', version : '>=5.0.0')

executable('iopf_01', ['iopf_01.c', ccan_config_h],
  dependencies : [libvfn],
  link_with: [ccan_lib],
  include_directories : ccan_include,
  install: true
)

configure_file(
  input : 'test_iopf_01.py',
  output: 'test_iopf_01.py',
  copy: true
)
