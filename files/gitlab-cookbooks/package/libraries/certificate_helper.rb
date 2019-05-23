#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

require_relative 'helper'

class CertificateHelper
  include ShellOutHelper

  def initialize(trusted_cert_dir, omnibus_cert_dir, user_dir)
    @trusted_certs_dir = trusted_cert_dir
    @omnibus_certs_dir = omnibus_cert_dir
    @directory_hash_file = File.join(user_dir, "trusted-certs-directory-hash")
  end

  def whitelisted_files
    [
      File.join(@omnibus_certs_dir, "README"),
      File.join(@omnibus_certs_dir, "cacert.pem")
    ]
  end

  def is_x509_certificate?(file)
    return false unless valid?(file)

    begin
      OpenSSL::X509::Certificate.new(File.read(file)) # DER- or PEM-encoded
      true
    rescue OpenSSL::X509::CertificateError => e
      warn("ERROR: " + file + ": OpenSSL error: " + e.message + "!")
      false
    rescue StandardError => e
      warn(e.message)
      false
    end
  end

  # If the number of files between the two directories is different
  # something got added so trigger the run
  def new_certificate_added?
    return true unless File.exist?(@directory_hash_file)

    stored_hash = File.read(@directory_hash_file)
    trusted_certs_dir_hash != stored_hash
  end

  def trusted_certs_dir_hash
    files = Dir[File.join(@trusted_certs_dir, "*"), File.join(@omnibus_certs_dir, "*")]
    files_modification_time = files.map { |name| File.stat(name).mtime if valid?(name) }
    Digest::SHA1.hexdigest(files_modification_time.join)
  end

  # Get all files in /opt/gitlab/embedded/ssl/certs
  # - "cacert.pem", "README" -> ignore
  # - if valid certificate
  #   - if symlink
  #     - remove broken symlinks
  #     - ignore if pointing to /etc/gitlab/trusted-certs
  #     - ignore because it might be a symlink user created
  #   - else
  #     - copy to trusted-certs dir
  # - else (not valid)
  #   raise and error
  def move_existing_certificates
    Dir.glob(File.join(@omnibus_certs_dir, "*")) do |file|
      next if !valid?(file) || whitelisted?(file)

      if is_x509_certificate?(file)
        move_certificate(file)
      else
        raise_msg(file)
      end
    end
  end

  def whitelisted?(file)
    whitelisted_files.include?(file) || whitelisted_files.include?(File.realpath(file))
  end

  def valid?(file)
    exists = File.exist?(file)
    FileUtils.rm_f(file) if File.symlink?(file) && !exists

    exists
  end

  def move_certificate(file)
    return if exists_in_trusted?(file)

    # Move the certs to the trusted certs directory if it is located within our managed certs directory
    # Otherwise copy the cert to the trusted certs directory
    realpath = File.realpath(file)
    if realpath.start_with?(@omnibus_certs_dir)
      FileUtils.mv(realpath, @trusted_certs_dir, force: true)
    else
      FileUtils.cp(realpath, @trusted_certs_dir)
    end

    FileUtils.rm_f(file) if File.symlink?(file)
    puts "\n Moving #{realpath}"
  end

  def exists_in_trusted?(file)
    trusted_path = File.join(@trusted_certs_dir, File.basename(file))

    (File.symlink?(file) && File.readlink(file).start_with?(@trusted_certs_dir)) ||
      (File.exist?(trusted_path) && FileUtils.identical?(file, trusted_path))
  end

  def link_certificates
    update_permissions
    c_rehash
    link_to_omnibus_ssl_directory
    log_directory_hash
  end

  # c_rehash ran so we now have valid hashed names
  # Skip all files that are not symlinks
  # If they are symlinks, make sure they are valid certificates
  def link_to_omnibus_ssl_directory
    Dir.glob(File.join(@trusted_certs_dir, "*")) do |trusted_cert|
      if File.symlink?(trusted_cert) && is_x509_certificate?(trusted_cert)
        hash_name = File.basename(trusted_cert)
        certificate_path = File.realpath(trusted_cert)
        symlink_path = File.join(@omnibus_certs_dir, hash_name)

        puts "\n Linking #{hash_name} from #{certificate_path}"

        FileUtils.ln_s certificate_path, symlink_path unless File.exist?(symlink_path)
      end
    end
  end

  def update_permissions
    files_directories = Dir.glob(File.join(@trusted_certs_dir, '*'))

    # Only operate on files
    file_list = files_directories.reject { |f| File.directory?(f) }
    FileUtils.chmod(0644, file_list)
  end

  def c_rehash
    cmd = "/opt/gitlab/embedded/bin/c_rehash #{@trusted_certs_dir}"
    result = do_shell_out(cmd)
    result.exitstatus
  end

  def log_directory_hash
    File.write(@directory_hash_file, trusted_certs_dir_hash)
  end

  def raise_msg(file)
    raise "ERROR: Not a certificate: #{File.realpath(file)}. Move it from #{File.realpath('..', file)} to a different location and reconfigure again."
  end
end
