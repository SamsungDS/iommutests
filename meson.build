project('iommutests', 'c')
cc = meson.get_compiler('c')

# Require at least python 3.0
py_inst = import('python').find_installation(modules: ['pyudev', 'pytest'])
if py_inst.language_version().version_compare('<=3.0')
  error('Python version must be greater than 3.0')
endif

subdir('ccan')
subdir('tests')

