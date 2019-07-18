property :cn, String, name_property: true
property :crt, String
property :dir, [String, nil]
property :key, String
property :owner, [String, nil]
property :chain, [String, nil]
property :wwwroot, String
property :alt_names, Array
property :key_size, [Integer, nil]
property :crt, [String, nil]
property :group, [String, nil]
property :contact, [String, Array, nil]

actions :create
default_action :create
