name "readline"
default_version "6.2"

# http://buildroot-busybox.2317881.n4.nabble.com/PATCH-readline-link-directly-against-ncurses-td24410.html
# https://bugzilla.redhat.com/show_bug.cgi?id=499837
# http://lists.osgeo.org/pipermail/grass-user/2003-September/010290.html
# http://trac.sagemath.org/attachment/ticket/14405/readline-tinfo.diff
dependency "ncurses"

source :url => "ftp://ftp.cwru.edu/pub/bash/readline-6.2.tar.gz",
       :md5 => "67948acb2ca081f23359d0256e9a271c"

relative_path "#{name}-#{version}"

build do
  env = {
      "CFLAGS" => "-I#{install_dir}/embedded/include",
      "LDFLAGS" => "-Wl,-rpath,#{install_dir}/embedded/lib -L#{install_dir}/embedded/lib"
  }

  configure_command = [
      "./configure",
      "--with-curses",
      "--prefix=#{install_dir}/embedded"
  ].join(" ")

  patch :source => "readline-6.2-curses-link.patch" , :plevel => 1
  command configure_command, :env => env
  command "make", :env => env
  command "make install", :env => env

end
