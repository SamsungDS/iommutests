project('iommutests', 'c')
cc = meson.get_compiler('c')

iommut_install_dir = 'share/iommut'

subdir('ccan')
subdir('tests')

# Point iommut to installed tests
configure_file(
  input: 'iommut',
  output: 'iommut',
  configuration: {'IOMMUT_INSTALL_DIR': get_option('prefix') / iommut_install_dir},
  install: true,
  install_dir: get_option('bindir')
)
