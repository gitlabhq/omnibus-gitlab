#
# Copyright:: Copyright (c) 2014 GitLab.com
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

define :template_symlink, :link_from => nil, :source => nil, :owner => nil, :group => nil, :mode => nil, :variables => nil, :helpers => nil, :notifies => nil, :restarts => [], :action => :create do
  template params[:name] do
    source params[:source]
    owner params[:owner]
    group params[:group]
    mode params[:mode]
    variables params[:variables]
    helpers *params[:helpers] if params[:helpers]
    notifies *params[:notifies] if params[:notifies]
    params[:restarts].each do |resource|
      notifies :restart, resource
    end
    action params[:action]
  end

  link params[:link_from] do
    to params[:name]
    action params[:action]
  end
end
