load "config.rb"

task :default => ["yap"]

SRC = %w[main_window.rb mw_model.rb mw_components.rb line_prompt.rb notification.rb
         channel_info_label.rb channel_name_label.rb
	 channel.rb settings_dialog.rb yellowpage.rb
         channeldb.rb info_dialog.rb sound.rb config.rb extensions.rb
         resource.rb threadhack.rb favorite_dialog.rb log_dialog.rb
         settings.rb yap.rb] 

file 'yap' => SRC do |task|
  sh "ruby rc.rb -o yap yap.rb"
end

task :clean do
  sh "rm -f yap"
end

task :install => ["yap"] do
  sh "install yap #{$BIN_DIR}"
  sh "mkdir -p #{$RESOURCE_DIR}"
  sh "cp yap.png loading.ico play.ico question16.ico question64.ico #{$RESOURCE_DIR}"
end

task :uninstall do
  sh "rm -vf #{$BIN_DIR}/yap"
  sh "rm -rvf #{$RESOURCE_DIR}"
end
