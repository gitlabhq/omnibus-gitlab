class LinkerHelper
  class << self
    def ldconfig
      ldconfig_raw_output = IO.popen(%w[ldconfig -p], &:read)&.split("\n")&.map { |line| line.strip }
      ldconfig_raw_output.shift

      libraries = {}
      ldconfig_raw_output.each do |line|
        # Split `libz3.so.4 (libc6,x86-64) => /lib/x86_64-linux-gnu/libz3.so.4`
        # to ['libz3.so.4' '(libc6,x86-64)', '=>', '/lib/x86_64-linux-gnu/libz3.so.4']
        info = line.split(" ")
        libraries[info[0]] = info[-1]
      end

      libraries
    end

    def ldd(path)
      ldd_raw_output = IO.popen("ldd #{path}", &:read)&.split("\n")&.map { |line| line.strip }

      libraries = {}
      ldd_raw_output.each do |line|
        # Split `"libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007fc00abc8000)"`
        # to ["libz.so.1", "=>", "/lib/x86_64-linux-gnu/libz.so.1", "(0x00007fc00abc8000)"]
        info = line.split(" ")
        libraries[info[0]] = info[-2]
      end

      libraries
    end
  end
end
