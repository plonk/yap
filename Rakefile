load "config.rb"

task :default => ["yap"]

SRC = %w[channel.rb channel_info_label.rb channel_list_view.rb
         channel_name_label.rb child_process.rb gtk_helper.rb
         clv_context_menu.rb config.rb extensions.rb favorite_dialog.rb
         favorites.rb info_dialog.rb launcher.rb line_prompt.rb log_dialog.rb
         main_window.rb menutest.rb mw_components.rb mw_model.rb
         notification.rb object_list.rb process_manager.rb rc.rb relation.rb
         resource.rb settings.rb settings_dialog.rb sound.rb test_suite.rb
         threadhack.rb type.rb type_assoc_dialog.rb type_association.rb
         utility.rb yap.rb yellowpage.rb]

file 'yap' => SRC do |task|
  sh "ruby rc.rb -o yap yap.rb"
end

task :clean do
  sh "rm -f yap"
end

task :install => ["yap"] do
  sh "install yap #{$BIN_DIR}"
  sh "mkdir -p #{$RESOURCE_DIR}"
  sh "cp ui_definition.xml yap.png loading.ico play.ico question16.ico question64.ico #{$RESOURCE_DIR}"
end

task :uninstall do
  sh "rm -vf #{$BIN_DIR}/yap"
  sh "rm -rvf #{$RESOURCE_DIR}"
end

