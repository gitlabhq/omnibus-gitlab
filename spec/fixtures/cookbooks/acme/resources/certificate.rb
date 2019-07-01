property :cn, String, name_property: true
property :fullchain, String
property :key, String
property :owner, [String, nil]
property :chain, [String, nil]
property :wwwroot, String
property :alt_names, Array
property :key_size, [Integer, nil]
property :crt, [String, nil]
property :group, [String, nil]
property :contact, [String, Array, nil]
property :endpoint, String

actions :create
default_action :create
