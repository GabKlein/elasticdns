module Elasticdns
  class Config
    attr_accessor  :ec2_access_key_id, :ec2_secret_access_key, :ec2_attribute, :bind9_notify_file, :bind9_acl_masters_file, :bind9_named_conf_file, :bind9_zone_files, :bind9_checkconf_path, :bind9_checkzone_path, :bind9_init_cmd, :bind9_masters

    def initialize(options={})
      @config_from_file = from_file(options[:config_file])

      @test = options[:test]
      @slave =options[:slave]

      @debug = options[:debug] || (@config_from_file['debug'] if @config_from_file)

      @ec2_access_key_id = options[:ec2_access_key_id] || (@config_from_file['ec2']['access_key_id'] if @config_from_file)
      @ec2_secret_access_key = options[:ec2_secret_access_key] || (@config_from_file['ec2']['secret_access_key'] if @config_from_file)
      @ec2_region = options[:ec2_region] || (@config_from_file['ec2']['region'] if @config_from_file)
      @ec2_tag_attribute = options[:ec2_tag_attribute] || (@config_from_file['ec2']['tag_attribute'] if @config_from_file)
      @ec2_ip_attribute = options[:ec2_ip_attribute] || (@config_from_file['ec2']['ip_attribute'] if @config_from_file)

      @bind9_notify_file = options[:bind9_notify_file] || (@config_from_file['bind9']['notify_file'] if @config_from_file)
      @bind9_acl_masters_file = options[:bind9_acl_masters_file] || (@config_from_file['bind9']['acl_masters_file'] if @config_from_file)
      @bind9_named_conf_file = options[:bind9_named_conf_file] || (@config_from_file['bind9']['named_conf_file'] if @config_from_file)
      @bind9_zone_files = split(options[:bind9_zone_files]) || (@config_from_file['bind9']['zone_files'] if @config_from_file)
      @bind9_checkconf_path = options[:bind9_checkconf_path] || (@config_from_file['bind9']['checkconf_path'] if @config_from_file)
      @bind9_checkzone_path = options[:bind9_checkzone_path] || (@config_from_file['bind9']['checkzone_path'] if @config_from_file)
      @bind9_init_cmd = options[:bind9_init_cmd] || (@config_from_file['bind9']['init_cmd'] if @config_from_file)
      @bind9_masters = split(options[:bind9_masters]) || (@config_from_file['bind9']['masters'] if @config_from_file)
    end

    def split(param)
      if param
        param.split(',')
      end
    end

    def to_hash
      hash = {}
      self.instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = self.instance_variable_get(var) }
      return hash
    end

    def from_file(config_file)
      if config_file && File.exists?(config_file)
       YAML.load_file(config_file)
      end      
    end
  end
end