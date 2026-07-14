---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `ncurses` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

This test plan verifies the ncurses library upgrade and its integration with dependent components.

### Pre-flight checks

- [ ] Performed a successful GitLab Enterprise Edition (EE) build on all supported platforms.
- [ ] Ran `qa-subset-test` CI/CD test job for both GitLab Enterprise Edition and GitLab Community Edition.

### Library verification

- [ ] Verify ncurses libraries are installed and linked correctly:

  ```shell
  IMAGE='registry.gitlab.com/gitlab-org/omnibus-gitlab/gitlab-ee:<MR_BRANCH_OR_TAG>'
  
  docker run -it --rm --platform="linux/amd64" $IMAGE bash -c "
    set -e
    echo '=== Checking ncurses libraries exist ==='
    ls -1 /opt/gitlab/embedded/lib/libncurses*.so* /opt/gitlab/embedded/lib/libtinfo*.so*
    
    echo -e '\n=== Verifying libedit links to ncurses/tinfo ==='
    ldd /opt/gitlab/embedded/lib/libedit.so | grep -E 'libtinfo|libncurses'
    
    echo -e '\n✓ ncurses libraries present and linked'
  "
  ```

  Expected: Libraries are present and libedit links to ncurses/tinfo (wide or non-wide variants).

### PostgreSQL functionality test

- [ ] Test `gitlab-psql` executes successfully with ncurses-dependent libedit:

  ```shell
  docker run -it --rm --platform="linux/amd64" $IMAGE bash -c "
    set -e
    gitlab-ctl reconfigure > /dev/null 2>&1
    gitlab-ctl start postgresql
    sleep 5
    
    echo '=== Testing basic psql command execution ==='
    gitlab-psql -d gitlabhq_production -c 'SELECT version();' | head -5
    
    echo -e '\n=== Testing UTF-8 character support ==='
    gitlab-psql -d gitlabhq_production -c \"SELECT 'ncurses UTF-8 test: 世界 🌍' AS test_output;\"
    
    echo -e '\n=== Testing multi-line query ==='
    gitlab-psql -d gitlabhq_production <<EOF
SELECT 
  schemaname, 
  tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
LIMIT 3;
EOF
    
    echo -e '\n✓ gitlab-psql works correctly with ncurses'
  "
  ```

  Expected: All queries execute successfully, UTF-8 displays correctly, no ncurses/terminfo errors.

### Python3 functionality test

- [ ] Test Python3 executes with ncurses support:

  ```shell
  docker run -it --rm --platform="linux/amd64" $IMAGE bash -c "
    set -e
    echo '=== Testing Python UTF-8 output ==='
    /opt/gitlab/embedded/bin/python3 -c 'print(\"Python ncurses test: 世界 🌍\")'
    
    echo -e '\n=== Testing Python readline module ==='
    /opt/gitlab/embedded/bin/python3 -c 'import readline; print(\"✓ readline module available\")'
  "
  ```

  Expected: Python executes successfully, UTF-8 output displays correctly.

### Dependency chain verification

- [ ] Verify ncurses consumers can load libraries without errors:

  ```shell
  docker run -it --rm --platform="linux/amd64" $IMAGE bash -c "
    set -e
    echo '=== Checking PostgreSQL binaries ==='
    ldd /opt/gitlab/embedded/postgresql/*/bin/psql | grep -E 'not found' && exit 1 || echo '✓ psql links correctly'
    
    echo -e '\n=== Checking Python binaries ==='
    ldd /opt/gitlab/embedded/bin/python3.* | grep -E 'not found' && exit 1 || echo '✓ python links correctly'
    
    echo -e '\n=== Checking for missing ncurses/tinfo dependencies (including widec variants) ==='
    MISSING=0
    for lib in libncurses libncursesw libtinfo libtinfow; do
      while read -r binary; do
        ldd \"\$binary\" 2>/dev/null | grep -q \"\$lib.*not found\" && echo \"ERROR: \$binary missing \$lib\" && MISSING=1
      done < <(find /opt/gitlab/embedded/bin /opt/gitlab/embedded/postgresql -type f -executable 2>/dev/null)
    done
    [ \$MISSING -eq 1 ] && exit 1
    
    echo -e '\n✓ No missing ncurses dependencies detected'
  "
  ```

  Expected: No "not found" errors for ncurses-related libraries (including widec variants).

````
