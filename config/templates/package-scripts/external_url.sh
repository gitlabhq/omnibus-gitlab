check_if_ec2()
{
  if [ -f /sys/hypervisor/uuid ] && [ `head -c 3 /sys/hypervisor/uuid` = 'ec2' ]; then
    return 0
  else
    return 1
  fi
}

get_ec2_address()
{
  url=$1
  # Try collecting fqdn if it is set correctly
  fqdn=$(/opt/gitlab/embedded/bin/curl -s ${url})
  if [ -n "${fqdn}" ]; then
    # Checking if curl returned an XML message
    word="<?xml"
    if ! $(test "${fqdn#*$word}" != "$fqdn"); then
        EXTERNAL_URL="http://${fqdn}"
    fi
  fi
}

get_details_from_ec2()
{
  get_ec2_address "http://169.254.169.254/latest/meta-data/public-hostname"
  if [ -z "${EXTERNAL_URL}" ]; then
    get_ec2_address "http://169.254.169.254/latest/meta-data/public-ipv4"
  fi
}

set_protocol()
{
  # Checking if EXTERNAL_URL starts with http:// or https://
  if ! $(echo ${EXTERNAL_URL} | awk '$0 !~ /^http[s]?:\/\// {exit 1}'); then
    EXTERNAL_URL="http://${EXTERNAL_URL}"
  fi
}

if [ -z "${EXTERNAL_URL}" ]; then
  # Grab address from EC2 only if this is first installation. For upgrades,
  # EXTERNAL_URL env variable is the only thing that may define external URL
  # other than what is in gitlab.rb
  if ! [ -e /etc/gitlab/gitlab.rb ] ; then
    check_if_ec2
    if [ $? -eq 0 ]  ; then
      get_details_from_ec2
    fi
  fi
else
    set_protocol
fi

if [ -z "${EXTERNAL_URL}" ]; then
  EXTERNAL_URL="http://gitlab.example.com"
fi
