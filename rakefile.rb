require 'yaml'
require 'aws-sdk'
require 'tempfile'
require 'fileutils'
require 'digest/md5'
import 'lib/ec2_dns.rb'

cnf = YAML::load(File.open('config.yml'))

task :update_hosts_file do
  
  orig_file = '/Users/uto/hosts'
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
        if i.tags[:meta_name]
          temp_file.write("#{i.private_ip_address}\t#{i.tags[:meta_name]}\t### EC2 HOSTS\n")
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

task :update_notify_file do  
  orig_file = cnf['bind9']['notify_file']
  temp_file = Tempfile.new('also-notify')
  prefix = "also-notify"
  begin
    ec2 = ec2init
    ips = []
    ec2.instances.each do |i|
      if i.status == :running
        ips << i.private_ip_address
      end
    end
    if ips[0]
      unless md5chk(orig_file, md5(ips.to_s))
        update = updatefile(ips, md5(ips.to_s), temp_file, orig_file, prefix)
        puts 'update with: ' + update
      else
        puts 'nothing changed: ' + md5(ips.to_s)
      end
    else
      puts 'no master'
    end
  ensure
    temp_file.close
    temp_file.unlink
  end
end

task :update_acl_masters_file do  
  orig_file = cnf['bind9']['acl_masters_file']
  temp_file = Tempfile.new('acl_masters_file')
  prefix = "acl 'masters'"
  begin
    ec2 = ec2init
    ips = []
    ec2.instances.each do |i|
      meta_name = i.tags[:meta_name]
      if i.status == :running
        cnf['bind9']['masters'].each do |master|
          if meta_name == master
            ips << i.private_ip_address
          end
        end
      end
    end
    if ips[0]
      unless md5chk(orig_file, md5(ips.to_s))
        update = updatefile(ips, md5(ips.to_s), temp_file, orig_file, prefix)
        puts 'update with: ' + update
      else
        puts 'nothing changed: ' + md5(ips.to_s)
      end
    else
      puts 'no master'
    end
  ensure
    closefile(temp_file)
  end
end