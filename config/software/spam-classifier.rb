#
## Copyright:: Copyright (c) 2021 GitLab Inc.
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name 'spam-classifier'

default_version '0.3.0'
source url: "https://glsec-spamcheck-ml-artifacts.storage.googleapis.com/spam-classifier/#{version}/linux.tar.gz",
       sha256: 'c9f7e147d195a45e32c35765e138e006e7636218f8c4413e67d0cef5513335a8'

license 'proprietary'
license_file 'LICENSE.md'

build do
  command "mkdir -p #{install_dir}/embedded/service/spam-classifier"
  sync './', "#{install_dir}/embedded/service/spam-classifier/", exclude: %w(dist tokenizer.pickle)
  copy "dist", "#{install_dir}/embedded/service/spam-classifier/preprocessor"
  copy "tokenizer.pickle", "#{install_dir}/embedded/service/spam-classifier/preprocessor/"
end
