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
   STDERR.puts "Something is not right, could not properly determine necessary info from path"
end

path_array.delete_at(base_klass_index + 1)

# Actual Vars used in ERB file.
klass_name = path_array[base_klass_index..-1].join("::") + "::" + output_file.sub(/\.pp$/, "")

