# Copyright:: Copyright (c) 2017 GitLab Inc
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

# Package attributes

# Default location of install-dir is /opt/gitlab.
# DO NOT change this value unless you are building your own GitLab packages
default['package']['install-dir'] = '/opt/gitlab'
default['package']['detect_init'] = true
default['package']['systemd_tasks_max'] = 4915

default['package']['systemd_wanted_by'] = 'multi-user.target'
default['package']['systemd_after'] = 'multi-user.target'

# Setting runit defaults here so that they can be made available automatically
# to cookbooks of individual services via depends in metadata.rb
default['runit']['sv_bin'] = '/opt/gitlab/embedded/bin/sv'
default['runit']['chpst_bin'] = '/opt/gitlab/embedded/bin/chpst'
default['runit']['service_dir'] = '/opt/gitlab/service'
default['runit']['sv_dir'] = '/opt/gitlab/sv'
default['runit']['lsb_init_dir'] = '/opt/gitlab/init'
