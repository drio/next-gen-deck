watch( 'test/tests.rb' )  {|md| system("ruby test/tests.rb") }
watch( 'lib/(.*)\.rb' )   {|md| system("ruby test/tests.rb") }
