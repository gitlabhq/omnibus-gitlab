property :cn, String, name_property: true
property :fullchain, String, required: true
property :key, String, required: true
property :owner, [String, nil], default: lazy { node['letsencrypt']['owner'] }
property :chain, [String, nil], default: lazy { node['letsencrypt']['chain'] }
property :wwwroot, String, default: lazy { node['letsencrypt']['wwwroot'] }
property :alt_names, Array, default: lazy { node['letsencrypt']['alt_names'] }
property :key_size, [Integer, nil], default: lazy { node['letsencrypt']['key_size'] }
property :crt, [String, nil], default: lazy { node['letsencrypt']['crt'] }
property :group, [String, nil], default: lazy { node['letsencrypt']['group'] }

action :create do
  # Attempt to fetch a certificate from Let's Encrypt staging instance
  # If that succeeds, then fetch a certificate from production
  # This helps protect users from hitting Let's Encrypt rate limits if
  # they provide invalid data
  helper = LetsEncryptHelper.new(node)
  contact_info = helper.contact

  acme_certificate 'staging' do
    alt_names new_resource.alt_names unless new_resource.alt_names.empty?
    key_size new_resource.key_size unless new_resource.key_size.nil?
    group new_resource.group unless new_resource.group.nil?
    owner new_resource.owner unless new_resource.owner.nil?
    chain "#{new_resource.chain}-staging" unless new_resource.chain.nil?
    crt "#{new_resource.crt}-staging" unless new_resource.crt.nil?
    contact contact_info
    fullchain "#{new_resource.fullchain}-staging"
    cn new_resource.cn
    key "#{new_resource.key}-staging"
    endpoint 'https://acme-staging.api.letsencrypt.org/'
    wwwroot new_resource.wwwroot
    sensitive true
  end

  ruby_block 'reset private key' do
    block do
      node.normal['acme']['private_key'] = nil
    end
  end

  acme_certificate 'production' do
    alt_names new_resource.alt_names unless new_resource.alt_names.empty?
    key_size new_resource.key_size unless new_resource.key_size.nil?
    group new_resource.group unless new_resource.group.nil?
    owner new_resource.owner unless new_resource.owner.nil?
    chain new_resource.chain unless new_resource.chain.nil?
    crt new_resource.crt unless new_resource.crt.nil?
    contact contact_info
    fullchain new_resource.fullchain
    cn new_resource.cn
    key new_resource.key
    wwwroot new_resource.wwwroot
    notifies :run, 'execute[reload nginx]'
    sensitive true
  end
end
