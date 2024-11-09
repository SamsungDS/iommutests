project('iommutests', 'c')
cc = meson.get_compiler('c')

subdir('ccan')

libvfn = dependency('libvfn', version : '>=5.0.0')
executable('dma_01', ['tests/dma_01.c', ccan_config_h],
  dependencies : [libvfn],
  link_with: [ccan_lib],
  include_directories : ccan_include
)

