project('iommutests', 'c')

cc = meson.get_compiler('c')

libvfn = dependency('libvfn', version : '>=5.0.0')
executable('dma_01', 'tests/dma_01.c',
  dependencies : [libvfn] )

subdir('ccan')
