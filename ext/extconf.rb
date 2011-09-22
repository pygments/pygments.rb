require 'mkmf'

python = %w[ 2.7 2.6 2.5 2.4 ].find do |version|
  have_library("python#{version}", 'Py_Initialize', "python#{version}/Python.h")
end

$CFLAGS << " -Wall "

unless python
  $stderr.puts '*** could not find libpython or Python.h'
else
  $defs << "-DPYGMENTS_PYTHON_VERSION=#{python.gsub('.','')}"
  create_makefile('pygments_ext')
end
