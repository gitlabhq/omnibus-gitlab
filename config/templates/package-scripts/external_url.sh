check_if_ec2()
{
  if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` = 'ec2' ]; then
    return 0
  else
    return 1
  fi
}

get_ec2_hostname()
{
  # Try collecting fqdn if it is set correctly
  fqdn=$(/opt/gitlab/embedded/bin/curl -s http://169.254.169.254/latest/meta-data/public-hostname)
  if [ -n "${fqdn}" ]; then
    EXTERNAL_URL="http://${fqdn}"
  fi
}

if [ -z "${EXTERNAL_URL}" ]; then
  check_if_ec2
  if [ $? -eq 0 ]  ; then
    get_ec2_hostname
  else
    EXTERNAL_URL="http://gitlab.example.com"
  fi
fi
