name "git"
version "1.8.5.3"

dependency "zlib"
dependency "openssl"
dependency "curl"

source :url => "https://git-core.googlecode.com/files/git-#{version}.tar.gz",
       :md5 => "57b966065882f83ef5879620a1e329ca"

relative_path 'git-#{version}'

env = {
  "LDFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "CFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "LD_RUN_PATH" => "#{install_dir}/embedded/lib",
}

build do
  command ["./configure",
           "--prefix=#{install_dir}/embedded",
           "--with-curl=#{install_dir}/embedded",
           "--with-ssl=#{install_dir}/embedded",
           "--with-zlib=#{install_dir}/embedded"].join(" "), :env => env

  # Ugly hack because ./configure does not pick these up from the env
  block do
    open(File.join(project_dir, "config.mak.autogen"), "a") do |file|
      file.print <<-EOH
# Added by Omnibus git software definition git.rb
NO_PERL=YesPlease
NO_EXPAT=YesPlease
NO_TCLTK=YesPlease
NO_GETTEXT=YesPlease
NO_PYTHON=YesPlease
      EOH
    end
  end

  command "make -j #{max_build_jobs}", :env => env
  command "make install"
end
