libvfn = dependency('libvfn', version : '>=5.0.0')

executable('iopf_01', ['iopf_01.c', ccan_config_h],
  dependencies : [libvfn],
  link_with: [ccan_lib],
  include_directories : ccan_include,
  install: true,
  install_dir: 'share/iommut/tests/pci/ats'
)

install_data('test_iopf_01.py', install_dir: 'share/iommut/tests/pci/ats')
