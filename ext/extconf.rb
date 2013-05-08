require 'mkmf'

# If Python 3 is set as default, port vendor through 2to3.
if `python -c 'import sys; print(sys.version[0])'`.start_with? '3'
  system('cd ../vendor/pygments-main/' +
    ' && 2to3 -w .' +
    ' && 2to3 -w -d .' +
    ' && 2to3 -w -d docs/src/*.txt')

end

create_makefile('pygments.rb')
