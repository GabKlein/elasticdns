def ec2init(access_key_id, secret_access_key)
  AWS::EC2.new(:access_key_id => cnf['ec2']['access_key_id'], :secret_access_key => cnf['ec2']['secret_access_key'])
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