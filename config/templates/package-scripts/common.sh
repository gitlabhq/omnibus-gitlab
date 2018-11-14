# Required for non-erroring upgrades from the old full path install log_directory
# 9.6.8 is the last postgres version where we used this old path
# @TODO: Remove in GitLab 12
symlink_old_postgres_directory()
{
  postgres_dir="${DEST_DIR}/embedded/postgresql/9.6"
  symlink_name="${DEST_DIR}/embedded/postgresql/9.6.8"
  if [ -d $postgres_dir ]; then
    # Remove the existing directory if exists and is not already a symlink
    if ! [ -L $symlink_name ]; then
      rm -rf $symlink_name
    fi

    # create/update the symlink
    ln -sfn $postgres_dir $symlink_name
  fi
}
