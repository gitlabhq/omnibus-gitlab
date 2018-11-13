# Required for non-erroring upgrades from the old full path install log_directory
# 9.6.8 is the last postgres version where we used this old path
# @TODO: Remove in GitLab 12
symlink_old_postgres_directory()
{
  postgres_dir="${DEST_DIR}/embedded/postgresql/9.6"
  if [ -d $postgres_dir ]; then
    ln -sfn $postgres_dir ${DEST_DIR}/embedded/postgresql/9.6.8
  fi
}
