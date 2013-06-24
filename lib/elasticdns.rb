require 'yaml'
require 'aws-sdk'
require 'tempfile'
require 'fileutils'
require 'digest/md5'
require 'pp'
require_relative 'config'

module Elasticdns
  class Generator
    def initialize(options={})
      @config = Elasticdns::Config.new(options).to_hash
    end

    def run
      pp @config if @config[:debug]
      if @config[:slave] == 'true'
        update_acl_masters_file
      else
        update_notify_file
      end
    end

    def ec2init
      AWS.memoize do
        AWS::EC2.new(:access_key_id => @config[:ec2_access_key_id], :secret_access_key => @config[:ec2_secret_access_key], :region => @config[:ec2_region])
      end
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
      end if File.exists?(orig_file)
      return false
    end

    def updatefile(ips, new_md5, temp_file, orig_file, prefix)
      puts "Updating #{orig_file}"
      md5 = "### MD5:#{new_md5}\n"
      line = "#{prefix} { #{ips.to_s.gsub(/\[|\]|"/, '').gsub(/,/, ';')}; };\n"
      temp_file.write(md5)
      temp_file.write(line)
      temp_file.rewind
      FileUtils.mv(temp_file.path, orig_file)
      return line
    end

    def bind_checkconf
      cmd = "#{@config[:bind9_checkconf_path]} #{@config[:bind9_named_conf_file]}"
      puts cmd if @config[:debug]
      unless system(cmd)
        puts "Bind checkconf failed"
        return false
      else
        return true
      end
    end

    def bind_checkzone
      @config[:bind9_zone_files].each do |zone|
        cmd = "#{@config[:bind9_checkzone_path]} #{zone}"
        puts cmd if @config[:debug]
        unless system(cmd)
          puts "Bind checkzone failed"
          return false
        else
          return true
        end
      end
    end

    def bind_init_cmd
      if bind_checkconf && bind_checkzone
        system("#{@config[:bind9_init_cmd]}")
      end
    end

    def update_hosts_file
      orig_file = '/etc/hosts'
      temp_file = Tempfile.new('hosts')
      begin
        ec2 = ec2init
        File.open(orig_file, 'r') do |file|
          file.each_line do |line|
            unless line =~ /### EC2 HOSTS/
              temp_file.write("#{line}")
            end
          end
        end
        ec2.instances.each do |i|
          if i.status == :running
            if i.tags[@config[:ec2_tag_attribute]]
              temp_file.write("#{i.private_ip_address}\t#{i.tags[@config[:ec2_tag_attribute]]}\t### EC2 HOSTS\n")
            end
          end
        end
        temp_file.rewind
        FileUtils.mv(temp_file.path, orig_file)
      ensure
        temp_file.close
        temp_file.unlink
      end
    end

    def update_notify_file
      # File dedicated to master servers
      orig_file = @config[:bind9_notify_file]
      temp_file = Tempfile.new('also-notify')
      prefix = "also-notify"
      begin
        ec2 = ec2init
        ips = []
        ec2.instances.each do |i|
          if i.status == :running
            ips << i.send(@config[:ec2_ip_attribute])
            #unless @config[:bind9_masters].include?(i.tags[@config[:ec2_tag_attribute]])
          end
        end
        write_to_file(ips, orig_file, temp_file, prefix)
      ensure
        temp_file.close
        temp_file.unlink
      end
    end

    def update_acl_masters_file
      # File dedicated to slave servers
      orig_file = @config[:bind9_acl_masters_file]
      temp_file = Tempfile.new('acl_masters_file')
      prefix = "acl 'masters'"
      begin
        ec2 = ec2init
        ips = []
        ec2.instances.each do |i|
          meta_name = i.tags[@config[:ec2_tag_attribute]]
          if i.status == :running
            @config[:bind9_masters].each do |master|
              if meta_name == master
                ips << i.send(@config[:ec2_ip_attribute])
              end
            end
          end
        end
        write_to_file(ips, orig_file, temp_file, prefix)
      ensure
        closefile(temp_file)
      end
    end

    def write_to_file(ips, orig_file, temp_file, prefix)
      if ips[0]
        unless md5chk(orig_file, md5(ips.to_s))
          update = updatefile(ips, md5(ips.to_s), temp_file, orig_file, prefix)
          bind_init_cmd
          puts "#{orig_file} updated with: " + update
        else
          puts "nothing changed in #{orig_file}: " + md5(ips.to_s)
        end
      else
        puts 'No master found'
      end
    end
  end
end
