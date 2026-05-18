#!/usr/bin/env bats

OPENBAO_CONF="/var/opt/gitlab/nginx/conf/service_conf/gitlab-openbao.conf"

setup_file() {
  docker exec "${CONTAINER}" bash -c "
    cat > /etc/gitlab/gitlab.rb << 'GITLAB_RB'
external_url 'http://gitlab.example.com'

oak['enable'] = true
oak['network_address'] = '10.0.0.1'
oak['components'] = {
  'openbao' => {
    'enable' => true,
    'internal_url' => 'http://127.0.0.1:8200',
    'external_url' => 'http://openbao.example.com'
  }
}
GITLAB_RB
    gitlab-ctl reconfigure
  "

  echo "------------------------------" >&3
  echo "--- With OAK configuration ---" >&3
  echo "------------------------------" >&3
}

@test "OpenBao NGINX config file exists" {
  run docker exec "${CONTAINER}" test -f "${OPENBAO_CONF}"
  [ "$status" -eq 0 ]
}

@test "config has correct server_name" {
  run docker exec "${CONTAINER}" grep -q "server_name openbao.example.com" "${OPENBAO_CONF}"
  [ "$status" -eq 0 ]
}

@test "config has correct proxy_pass" {
  run docker exec "${CONTAINER}" grep -q "proxy_pass http://127.0.0.1:8200" "${OPENBAO_CONF}"
  [ "$status" -eq 0 ]
}

@test "proxy routes requests to mock OpenBao backend" {
  run docker exec "${CONTAINER}" curl -s -o /dev/null -w "%{http_code}" \
    --header "Host: openbao.example.com" http://localhost:80/
  [ "$output" = "200" ]
}
