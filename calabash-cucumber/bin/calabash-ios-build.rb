def ensure_build_dir(options={:build_dir => "Calabash"})
  if !File.exist?(options[:build_dir])
    FileUtils.mkdir_p options[:build_dir]
  end
end

def build(options={:build_dir=>"Calabash",
                   :configuration => "Debug",
                   :sdk => "iphonesimulator",
                   :dstroot => "Calabash/build",
                   :wrapper_name => "Calabash.app"})
  #Follow Pete's .xcconfig-based approach with zero-config

  ensure_build_dir(options)

  if !File.exists?("#{options[:build_dir]}/cal.xcconfig")
      FileUtils.cp(File.join(File.dirname(__FILE__),"cal.xcconfig"),"#{options[:build_dir]}/cal.xcconfig")
  end

  cmd=["xcodebuild"]
  cmd << %Q[-xcconfig "#{options[:build_dir]}/cal.xcconfig"]
  cmd << "install"

  (options[:target] || []).each do |tgt|
    options << %Q[-target "#{tgt}"]
  end

  cmd << "-configuration"
  cmd << %Q["#{options[:configuration]}"]

  cmd << "-sdk"
  cmd << %Q["#{options[:sdk]}"]

  cmd << %Q[DSTROOT="#{options[:dstroot]}"]

  cmd << %Q[WRAPPER_NAME="#{options[:wrapper_name]}"]

  res =nil
  msg("Calabash Build") do
    cmd_s = cmd.join(" ")
    puts cmd_s
    res=system(cmd_s)
  end
  res
end

def console(options={:script => "irb_ios5.sh"})
  if !File.exists?(".irbrc")
    puts "Copying calabash-ios .irbrc file to current directory..."
    FileUtils.cp(File.join(@source_dir,".irbrc"), ".")
  end
  if !File.exists?(options[:script])
    puts "Copying calabash-ios #{options[:script]} file to current directory..."
    FileUtils.cp(File.join(@source_dir,options[:script]), ".")
  end
  puts "Running irb with ./.irbrc..."
  system("./#{options[:script]}")
end


def run(options={:build_dir=>"Calabash",
                   :configuration => "Debug",
                   :sdk => "iphonesimulator",
                   :dstroot => "Calabash/build",
                   :wrapper_name => "Calabash.app"})
  if ENV['NO_DOWNLOAD'] != "1"
    if !File.directory?("calabash.framework")
      calabash_download(ARGV)
    end
  end

  if ENV['NO_BUILD'] != "1"
    if !build(options)
      msg("Error") do
        puts "Build failed. Please consult logs. Aborting."
        exit(false)
      end
    end
  end

  if ENV["NO_GEN"] != "1"
    if !File.directory?("features")
      calabash_scaffold
    else
      msg("Info") do
        puts "Detected features folder, will not generate..."
      end
    end
  end

  default_path = "#{options[:dstroot]}/#{options[:wrapper_name]}"
  cmd = %Q[APP_BUNDLE_PATH="#{ENV['APP_BUNDLE_PATH'] || default_path}" cucumber]
  msg("Info") do
    puts "Running command:"
    puts cmd
  end
  system(cmd)
  puts "Done..."
end