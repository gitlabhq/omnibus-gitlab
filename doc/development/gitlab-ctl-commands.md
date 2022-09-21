---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Adding new `gitlab-ctl` commands

New `gitlab-ctl` commands can be added to two directory : `files/gitlab-ctl-commands` and `files/gitlab-ctl-commands-ee`. Chef stores `gitlab-ctl` commands in `/opt/gitlab/embedded/service/omnibus-ctl`.

There are two main functions you will use to add commands (<https://github.com/chef/omnibus-ctl>):

## add_command_under_category(string, string, string, int, ruby_block)

This method will add a new command to your `gitlab-ctl` under a category, useful for grouping similar commands together logically in help output.

Input arguments:

1. Name of the command.
1. Category of the command. It should be string consisting of only characters and "-". If the category does not exist, it will be added. Default categories are "general" and "service-management" (if the latter is enabled).
1. Description. This will be outputted below the command name when the help command is run.
1. Arity. Always set to `2`, due to [a bug in `omnibus-ctl`](https://github.com/chef/omnibus-ctl#add_command_under_categorystring-string-string-int-ruby_block).
1. Ruby block. Ruby code to be executed when your command is run (arguments to that command will be passed into the block).

## add_command(string, string, int, ruby_block)

This method will add a new command to your `gitlab-ctl` without a category. It will be displayed above all categories when the help command is called.

Input arguments are the same as `add_command_under_category` except 2 doesn't exist.
