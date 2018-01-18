property :cn, String, name_property: true
property :crt, String
property :key, String
property :chain, String
property :contact, Array, default: []
property :owner, String
property :wwwroot, String

action :create do
  acme_certificate 'staging' do
    chain "new_resource.chain}-staging"
    crt "#{new_resource.crt}-staging"
    cn new_resource.cn
    key "#{new_resource.key}-staging"
    owner new_resource.owner
    endpoint 'https://acme-staging.api.letsencrypt.org/'
    wwwroot new_resource.wwwroot
    contact new_resource.contact
  end

  acme_certificate 'production' do
    chain new_resource.chain
    crt new_resource.crt
    cn new_resource.cn
    key new_resource.key
    owner new_resource.owner
    wwwroot new_resource.wwwroot
    contact new_resource.contact
    notifies :run, 'execute[reload nginx]'
  end
end
