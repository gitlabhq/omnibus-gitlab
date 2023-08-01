# libre2 component upgrade test plan

## Test plan

- [ ] Green pipeline on gitlab.com including `Trigger:ce-package` and `Trigger:ee-package`. These pipelines should have ran their respective `build-package-on-all-os` pipelines.
- [ ] Verified build options for CC and CXX are correct.
  -[ ] CentOS 7
  -[ ] Modern OS, e.g Ubuntu jammy.
- [ ] Installed package or container. Verified no installation issues.
  -[ ] CentOS 7
  -[ ] Modern OS
- Ran ldd on re2 gem and verified correct `libre2`` library is used.
  -[ ] CentOS 7
  -[ ] Modern OS
- [ ] Ran `re2` Spec test to verify correct ruby integration:

  ```shell
  docker run -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:4.10.0 bash
  cd /tmp
  git clone -b 2023-03-01 https://github.com/google/re2 google-re2
  git clone -b v1.6.0 https://github.com/mudge/re2.git
  cd google-re2
  make install
  cd ..
  cd re2
  bundle install
  bundle exec rake compile
  bundle exec rspec
  ```

- [ ] Ran gitlab-rails console smoke test
  - [ ] CentOS 7
  - [ ] Modern OS

  ```ruby
  irb(main):005:0> regex = RE2('\(iP.+; CPU .*OS (\d+)[_\d]*.*\) AppleWebKit\/')
  => #<RE2::Regexp /\(iP.+; CPU .*OS (\d+)[_\d]*.*\) AppleWebKit\//>
  irb(main):006:0> regex.match?('foo')
  => false
  irb(main):017:0> regex.match?("Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1")
  => true
  ```
