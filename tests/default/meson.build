libvfn = dependency('libvfn', version : '>=5.0.0')

executable('dma_01', ['dma_01.c', ccan_config_h],
  dependencies : [libvfn],
  link_with: [ccan_lib],
  include_directories : ccan_include
)

configure_file(
  input : 'test_dma_01.py',
  output: 'test_dma_01.py',
  copy: true
)

