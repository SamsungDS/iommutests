project('iommutests', 'c')
cc = meson.get_compiler('c')

iommut_install_dir = 'share/iommut'

subdir('ccan')
subdir('tests')

install_data('iommut', install_dir: iommut_install_dir)
