require File.join(File.dirname(__FILE__), '/lib/pygments.rb')

# Simple marshalling
serialized_lexers = Marshal.dump(Pygments.lexers!)

# Write to a file
File.open("lexers", 'w') { |file| file.write(serialized_lexers) }

