add_command "remove_users", "Delete *all* users and groups used by gitlab", 2 do

  command = %W( chef-solo
                --config #{base_path}/embedded/cookbooks/solo.rb
                -o recipe[gitlab::clean]
             )

  status = run_command(command.join(" "))
  exit! 1 unless status.success?
end
