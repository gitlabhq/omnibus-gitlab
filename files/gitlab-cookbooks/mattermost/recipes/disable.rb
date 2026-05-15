#
# Copyright:: Copyright (c) 2015 GitLab Inc.
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

# The bundled Mattermost binary was removed in 19.0. This recipe stops and
# unsupervises any leftover runit service from an earlier install so it does
# not keep running in the background after upgrade. The matching NGINX
# reverse-proxy config is removed alongside the other service configs in
# `gitlab::nginx`. Safe to delete once the `mattermost` deprecation entry is
# removed at the next required upgrade stop.

runit_service "mattermost" do
  action :disable
end
