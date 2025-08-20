libvfn = dependency('libvfn', version : '>=5.0.0')

executable('dma_01', ['dma_01.c', ccan_config_h],
  dependencies : [libvfn],
  link_with: [ccan_lib],
  include_directories : ccan_include,
  install: true,
  install_dir: 'share/iommut/tests/demo0'
)

install_data('test_dma_01.py', install_dir: 'share/iommut/tests/demo0')

