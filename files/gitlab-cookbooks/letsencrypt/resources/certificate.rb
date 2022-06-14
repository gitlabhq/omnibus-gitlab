unified_mode true

property :cn, String, name_property: true
property :key, String, required: true
property :owner, [String, nil], default: lazy { node['letsencrypt']['owner'] }
property :wwwroot, String, default: lazy { node['letsencrypt']['wwwroot'] }
property :alt_names, Array, default: lazy { node['letsencrypt']['alt_names'] }
property :key_size, [Integer, nil], default: lazy { node['letsencrypt']['key_size'] }
property :crt, [String, nil], default: lazy { node['letsencrypt']['crt'] }
property :group, [String, nil], default: lazy { node['letsencrypt']['group'] }
property :acme_staging_endpoint, [String, nil], default: lazy { node['letsencrypt']['acme_staging_endpoint'] }
property :acme_production_endpoint, [String, nil], default: lazy { node['letsencrypt']['acme_production_endpoint'] }
property :chain, [String, nil],
         deprecated: 'chain has been deprecated since crt now returns the full certificate by default',
         default: lazy { node['letsencrypt']['chain'] }

deprecated_property_alias :fullchain, :crt,
                          'The fullchain property has been deprecated in favor of crt, and will be removed in GitLab 13.0'

action :create do
  # Attempt to fetch a certificate from Let's Encrypt staging instance
  # If that succeeds, then fetch a certificate from production
  # This helps protect users from hitting Let's Encrypt rate limits if
  # they provide invalid data
  helper = LetsEncryptHelper.new(node)
  contact_info = helper.contact
  target_key_size = new_resource.key_size || node['acme']['key_size']

  if ::File.file?("#{new_resource.key}-staging")
    staging_key = OpenSSL::PKey::RSA.new ::File.read "#{new_resource.key}-staging"
    staging_key_size = staging_key.n.num_bits

    if staging_key_size != target_key_size
      file "#{new_resource.key}-staging" do
        action :delete
      end
      file "#{new_resource.crt}-staging" do
        action :delete
      end
    end
  end

  acme_certificate 'staging' do
    alt_names new_resource.alt_names unless new_resource.alt_names.empty?
    key_size new_resource.key_size unless new_resource.key_size.nil?
    group new_resource.group unless new_resource.group.nil?
    owner new_resource.owner unless new_resource.owner.nil?
    chain "#{new_resource.chain}-staging" unless new_resource.chain.nil?
    contact contact_info
    crt "#{new_resource.crt}-staging"
    cn new_resource.cn
    key "#{new_resource.key}-staging"
    dir new_resource.acme_staging_endpoint
    wwwroot new_resource.wwwroot
    sensitive true
  end

  ruby_block 'reset private key' do
    block do
      node.normal['acme']['private_key'] = nil
    end
  end

  # Delete the private key_file
  file node['acme']['private_key_file'] do
    action :delete
  end

  if ::File.file?(new_resource.key)
    production_key = OpenSSL::PKey::RSA.new ::File.read new_resource.key
    production_key_size = production_key.n.num_bits

    if production_key_size != target_key_size
      file new_resource.key do
        action :delete
      end
      file new_resource.crt do
        action :delete
      end
    end
  end

  acme_certificate 'production' do
    alt_names new_resource.alt_names unless new_resource.alt_names.empty?
    key_size new_resource.key_size unless new_resource.key_size.nil?
    group new_resource.group unless new_resource.group.nil?
    owner new_resource.owner unless new_resource.owner.nil?
    chain new_resource.chain unless new_resource.chain.nil?
    contact contact_info
    crt new_resource.crt
    cn new_resource.cn
    key new_resource.key
    dir new_resource.acme_production_endpoint
    wwwroot new_resource.wwwroot
    notifies :run, 'execute[reload nginx]'
    sensitive true
  end

  # Delete the private key_file
  file node['acme']['private_key_file'] do
    action :delete
  end
end
