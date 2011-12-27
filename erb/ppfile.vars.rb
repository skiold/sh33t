# Some code to determine puppet sources, which aren't 1-1 mappings of dir-
# rectory structures.
environment = ""
environment_index = 0
base_klass_dir = ""
base_klass_index = 0

path_array = ENV['PWD'].split(File::SEPARATOR)

path_array.each_with_index do |dir,index|
   if path_array[index - 1] =~ /^.*puppet$/
      environment_index = index
      environment = dir
   elsif path_array[index - 1] == environment
      base_klass_index = index + 1
      base_klass_dir = path_array[index + 1]
   end
end

if environment.nil? or base_klass_dir.nil?
   STDERR.puts "Something is not right, could not properly determine file source"
end

file_source = path_array[environment_index..-1].join(File::SEPARATOR) + File::SEPARATOR + output_file

# Here are the actual variables used in the ppfile.erb
BASE_KLASS_DIR = base_klass_dir
FILE_SOURCE = file_source
