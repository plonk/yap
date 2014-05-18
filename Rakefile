load 'config.rb'

task default: ['yap']

SRC = Dir.glob('*.rb')

file 'yap' => SRC do |task|
  sh 'ruby rc.rb -o yap yap.rb'
end

task :clean do
  sh 'rm -f yap'
end

task install: ['yap'] do
  sh "install yap #{$BIN_DIR}"
  sh "mkdir -p #{$RESOURCE_DIR}"
  sh('cp ui_definition.xml yap.png loading.ico play.ico question16.ico question64.ico' \
     " #{$RESOURCE_DIR}")
end

task :uninstall do
  sh "rm -vf #{$BIN_DIR}/yap"
  sh "rm -rvf #{$RESOURCE_DIR}"
end

task :stats do
  sh 'wc -l *.rb */*.rb | sort -nr'
end
