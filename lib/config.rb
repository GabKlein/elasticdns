module Elasticdns
  class Config
    attr_accessor  :ec2_access_key_id, :ec2_secret_access_key, :ec2_attribute, :bind9_notify_file, :bind9_acl_masters_file, :bind9_named_conf_file, :bind9_zone_files, :bind9_init_file, :bind9_masters

    def initialize(options={})
      @ec2_access_key_id = options[:ec2_access_key_id] || config_from_file['ec2']['access_key_id']
      @ec2_secret_access_key = options[:ec2_secret_access_key] || config_from_file['ec2']['secret_access_key']
      @ec2_attribute = options[:ec2_attribute] || config_from_file['ec2']['attribute']

      @bind9_notify_file = options[:bind9_notify_file] || config_from_file['bind9']['notify_file']
      @bind9_acl_masters_file = options[:bind9_acl_masters_file] || config_from_file['bind9']['acl_masters_file']
      @bind9_named_conf_file = options[:bind9_named_conf_file] || config_from_file['bind9']['named_conf_file']
      @bind9_zone_files = options[:bind9_zone_files] || config_from_file['bind9']['zone_files']
      @bind9_init_file = options[:bind9_init_file] || config_from_file['bind9']['init_file']
      @bind9_masters = options[:bind9_masters] || config_from_file['bind9']['masters']
    end

    def to_hash
      hash = {}
      self.instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = self.instance_variable_get(var) }
      return hash
    end
  end
end