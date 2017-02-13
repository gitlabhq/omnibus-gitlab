name              "runit"
maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs runit and provides runit_service definition"
version           "0.14.2"
depends           "package"

recipe "runit", "Installs and configures runit"

%w{ ubuntu debian gentoo }.each do |os|
  supports os
end
