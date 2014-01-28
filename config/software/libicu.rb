name "libicu"
version "52.1"

source :url => "http://download.icu-project.org/files/icu4c/52.1/icu4c-52_1-src.tgz",
       :md5 => "9e96ed4c1d99c0d14ac03c140f9f346c"

relative_path 'icu/source'

env = {
  "LDFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "CFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "LD_RUN_PATH" => "#{install_dir}/embedded/lib"
}

build do
  command ["alias gmake=make; ./runConfigureICU",
           "Linux/gcc",
           "--prefix=#{install_dir}/embedded",
	   ].join(" "), :env => env

  command "make -j #{max_build_jobs}", :env => env
  command "make install"
end
