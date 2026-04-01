#
# Copyright:: Copyright (c) 2025 GitLab Inc.
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

#
# ABOUTME: Provides bash completion setup command for gitlab-ctl
# ABOUTME: Displays instructions for enabling bash completion in user's shell
#

add_command 'completion', 'Enable bash completion for gitlab-ctl', 1 do
  completion_script = File.join(base_path, 'embedded/share/bash-completion/completions/gitlab-ctl-bash-completion')

  unless File.exist?(completion_script)
    log "Error: Completion script not found at #{completion_script}"
    Kernel.exit 1
  end

  puts <<~COMPLETION
    Bash completion for gitlab-ctl is available.

    To enable it, add the following line to your shell configuration file
    (~/.bashrc, ~/.bash_profile, or equivalent):

      source #{completion_script}

    Then reload your shell configuration:

      source ~/.bashrc

    After that, you can use tab completion with gitlab-ctl commands:

      gitlab-ctl <TAB>

    Note: The bash-completion package must be installed on your system for this to work.
    Install it using your system's package manager:
      - Debian/Ubuntu: sudo apt-get install bash-completion
      - RHEL/CentOS: sudo yum install bash-completion

    For more information, see the documentation:
      https://docs.gitlab.com/omnibus/maintenance/#enable-bash-completion-for-gitlab-ctl
  COMPLETION
end
