require 'yaml'
require 'aws-sdk'
require 'tempfile'
require 'fileutils'
require 'digest/md5'


class Elasticdns
  def initialize(options={})
    @config = config(options)
  end

  def config(options={})
    @config || Elasticdns::Config.new(options).to_hash
  end

  def run
    puts "toot"
  end

end


@cnf = YAML::load(File.open('config.yml'))

def ec2init
  AWS::EC2.new(:access_key_id => @cnf['ec2']['access_key_id'], :secret_access_key => @cnf['ec2']['secret_access_key'])
end

def closefile(file)
  file.close
  file.unlink
end

def md5(string)
  md5 = Digest::MD5.hexdigest(string)
end

def md5chk(orig_file, new_md5)
  File.open(orig_file, 'r') do |file|
    file.each_line do |line|
      if line =~ /### MD5:/
        old_md5 = line.split(':')[1]
        if old_md5 =~ /#{new_md5}/
          return new_md5
        end
      end
    end
  end if exist?(orig_file)
  return false
end

def updatefile(ips, new_md5, temp_file, orig_file, prefix)
  md5 = "### MD5:#{new_md5}\n"
  line = "#{prefix} { #{ips.to_s.gsub(/\[|\]|"/, '').gsub(/,/, ';')}; };\n"
  temp_file.write(md5)
  temp_file.write(line)
  temp_file.rewind
  FileUtils.mv(temp_file.path, orig_file)
  return line
end

def bind_checkconf
  `named-checkconf #{cnf['bind9']['named_conf_file']}`
end

def bind_checkzone
  cnf['bind9']['zone_files'].each do |zone|
    `named-checkzone #{zone}`
  end
end

def bind_reload
  if bind_checkconf && bind_checkzone
    `#{cnf['bind9']['init_file']} reload`
  end
end