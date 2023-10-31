project(
    'pylibwdi',
    ['c', 'cython'],
    version: '1.5.0'
)

# locate python, see python_path option for details
py_path = get_option('python_path')
if py_path == ''
    py = import('python').find_installation(modules: ['cython'])
elif py_path.startswith('/')
    py = import('python').find_installation(py_path, modules: ['cython'])
else
    py = import('python').find_installation(
        meson.current_source_dir() / py_path,
        modules: ['cython'],
    )
endif

py_dep = py.dependency()

if not py_dep.found()
    error('Could not find python, which is required for cythonize')
endif

libwdi = subproject('libwdi')
libwdi_dep = libwdi.get_variable('libwdi_dep')

# Build cython extensions for libwdi
wdi_py = py.extension_module(
    'pylibwdi',
    'src' / 'pylibwdi.pyx',
    dependencies: [py_dep, libwdi_dep],
    override_options: ['cython_language=c'],
    cython_args: ['-I' + meson.source_root() / 'src'],
    link_args: ['-lsetupapi'],
    install: true,
)
