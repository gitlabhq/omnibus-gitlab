property :cn, String, name_property: true
property :crt, String, required: true
property :key, String, required: true
property :chain, String
property :contact, Array
property :owner, String
property :wwwroot, String
property :alt_names, Array
property :key_size, Integer
property :fullchain, String
property :group, String

action :create do
  acme_certificate 'staging' do
    alt_names new_resource.alt_names unless new_resource.alt_names.empty?
    key_size new_resource.key_size unless new_resource.key_size.nil?
    fullchain new_resource.fullchain unless new_resource.fullchain.nil?
    group new_resource.group unless new_resource.group.nil?
    chain "#{new_resource.chain}-staging"
    crt "#{new_resource.crt}-staging"
    cn new_resource.cn
    key "#{new_resource.key}-staging"
    owner new_resource.owner
    endpoint 'https://acme-staging.api.letsencrypt.org/'
    wwwroot new_resource.wwwroot
    contact new_resource.contact unless new_resource.contact.empty?
  end

  acme_certificate 'production' do
    alt_names new_resource.alt_names unless new_resource.alt_names.empty?
    key_size new_resource.key_size unless new_resource.key_size.nil?
    fullchain new_resource.fullchain unless new_resource.fullchain.nil?
    group new_resource.group unless new_resource.group.nil?
    chain new_resource.chain
    crt new_resource.crt
    cn new_resource.cn
    key new_resource.key
    owner new_resource.owner
    wwwroot new_resource.wwwroot
    contact new_resource.contact unless new_resource.contact.empty?
    notifies :run, 'execute[reload nginx]'
  end
end
