---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `libxml2` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Check which components use `libxml2`.

### Identify libxml2 dependencies

- [ ] Collect inventory of deployed binaries (libraries and executables):

  ```shell
  find /opt/ -type f -exec file \{\} \; \
    | grep ELF \
    | cut -d: -f1 \
    | tee  /tmp/inventory
  ```

- [ ] Check which binaries depend on `libxml2`:

  ```shell
  while read f ; do \
    sudo readelf -d "${f}" \
      | grep -q libxml && echo ${f}; \
  done < /tmp/inventory \
    | tee /tmp/libxml_clients
  ```

- [ ] Check which executables are being used from within GitLab:

  ```shell
  while read f ; do \
    if [[ -x "${f}" ]]; then \
      short_name="${f##*/}"; \
      grep -rF "${short_name}" /opt/gitlab; \
    fi; \
  done < /tmp/libxml_clients
  ```

### Test Nokogiri XML parsing

- [ ] Create test XML file:

  ```shell
  cat > /tmp/test.xml << 'EOF'
  <document>
    <header>Document Header</header>
    <body>Document body</body>
    <footer>Document footer</footer>
  </document>
  ```

- [ ] Enter Rails console:

  ```shell
  gitlab-rails console
  ```

  ```ruby
  doc = File.open("/tmp/a.xml") { |f| Nokogiri::XML(f) }
  doc.children
  ```

- [ ] Verify output shows parsed XML structure. For example:

  ```plaintext
  => [#<Nokogiri::XML::Element:0x9e5fc name="document" children=[#<Nokogiri::XML::Text:0xa3d68 "\n\t">, #<Nokogiri::XML::Element:0x9e78c name="header" children=[#<Nokogiri::XML::Text:0xa3d7c "Document Header">]>, #<Nokogiri::XML::Text:0xa3d90 "\n\t">, #<Nokogiri::XML::Element:0xa3db8 name="body" children=[#<Nokogiri::XML::Text:0xa3da4 "Document body">]>, #<Nokogiri::XML::Text:0xa3dcc "\n\t">, #<Nokogiri::XML::Element:0xa3df4 name="footer" children=[#<Nokogiri::XML::Text:0xa3de0 "Document footer">]>, #<Nokogiri::XML::Text:0xa3e08 "\n">]>]
  ```
