#
# Copyright:: Copyright (c) 2015 Chris Marchesi
# Copyright:: Copyright (c) 2016 GitLab Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'openssl'
require 'base64'

module SSHKeygen
  # Lightweight SSH key generator
  class Generator
    def initialize(bits, type, passphrase, comment)
      # set instance attributes
      @passphrase = passphrase
      @comment = comment
      @type = type

      case @type
      when 'rsa'
        @key = ::OpenSSL::PKey::RSA.new(bits)
      else
        fail "Invalid key type #{new_resource.type}"
      end
    end

    # return the public key (encrypted if passphrase is given), in PEM form
    def private_key
      if @passphrase.to_s.empty?
        @key.to_pem
      else
        cipher = ::OpenSSL::Cipher.new('AES-128-CBC')
        @key.export(cipher, @passphrase)
      end
    end

    # OpenSSH public key
    def ssh_public_key
      case @type
      when 'rsa'
        enc_pubkey = openssh_rsa_public_key
      else
        fail "Invalid key type #{new_resource.type} found in ssh_public_key method - serious error!"
      end
      "ssh-#{@type} #{enc_pubkey} #{@comment}\n"
    end

    # Encode an OpenSSH RSA public key.
    # Key format is PEM-encoded - size (big-endian), then data:
    #  * Type (ie: len: 7 (size of string), data: ssh-rsa)
    #  * Exponent (len/data)
    #  * Modulus (len+1/NUL+data)
    def openssh_rsa_public_key
      enc_type = "#{[7].pack('N')}ssh-rsa"
      enc_exponent = "#{[@key.public_key.e.num_bytes].pack('N')}#{@key.public_key.e.to_s(2)}"
      enc_modulus = "#{[@key.public_key.n.num_bytes + 1].pack('N')}\0#{@key.public_key.n.to_s(2)}"
      Base64.strict_encode64("#{enc_type}#{enc_exponent}#{enc_modulus}")
    end

    # Fingerprint (SHA1 digest, colon delimited)
    def key_fingerprint
      OpenSSL::Digest::SHA1.hexdigest(@key.public_key.to_der).scan(/../).join(':')
    end
  end

  # provider functions for the SSHKeygen Chef resoruce provider class
  module Helper
    def create_key
      converge_by("Create SSH #{new_resource.type} #{new_resource.strength}-bit key (#{new_resource.comment})") do
        @key = ::SSHKeygen::Generator.new(
          new_resource.strength,
          new_resource.type,
          new_resource.passphrase,
          new_resource.comment
        )
      end
    end

    def save_private_key
      converge_by("Create SSH private key at #{new_resource.path}") do
        f = file new_resource.path do
          action :nothing
          owner new_resource.owner
          group new_resource.group
          mode 0600
          sensitive true
        end
        f.content(@key.private_key)
        f.run_action(:create)
      end
    end

    def save_public_key
      converge_by("Create SSH public key at #{new_resource.path}") do
        f = file "#{new_resource.path}.pub" do
          action :nothing
          owner new_resource.owner
          group new_resource.group
          mode 0600
        end
        f.content(@key.ssh_public_key)
        f.run_action(:create)
      end
    end

    def update_directory_permissions
      return false unless new_resource.secure_directory
      converge_by("Update directory permissions at #{File.dirname(new_resource.path)}") do
        directory ::File.dirname(new_resource.path) do
          action :create
          owner new_resource.owner
          group new_resource.group
          mode 0700
        end
      end
    end
  end
end
