---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# OS Versions that are no longer supported

GitLab provides omnibus packages for operating systems only until their
EOL (End-Of-Life). After the EOL date of the OS, GitLab will stop releasing
official packages. The list of deprecated operating systems and the final GitLab
release for them can be found below:

| OS Version      | End Of Life                                                                        | Last supported GitLab version                                                                                                                                                                                                                              |
| --------------- | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Raspbian Wheezy | [May 2015](https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-05-07/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_8.17&dist=debian%2Fwheezy) 8.17                                                                                                                                        |
| OpenSUSE 13.2   | [January 2017](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-9.1&dist=opensuse%2F13.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-9.1&dist=opensuse%2F13.2) 9.1                                  |
| Ubuntu 12.04    | [April 2017](https://ubuntu.com/info/release-end-of-life)                          | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_9.1&dist=ubuntu%2Fprecise) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_9.1&dist=ubuntu%2Fprecise) 9.1                                |
| OpenSUSE 42.1   | [May 2017](https://en.opensuse.org/Lifetime#Discontinued_distributions)            | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-9.3&dist=opensuse%2F42.1) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-9.3&dist=opensuse%2F42.1) 9.3                                  |
| OpenSUSE 42.2   | [January 2018](https://en.opensuse.org/Lifetime#Discontinued_distributions)        | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-10.4&dist=opensuse%2F42.2) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-10.4&dist=opensuse%2F42.2) 10.4                               |
| Debian Wheezy   | [May 2018](https://www.debian.org/News/2018/20180601)                              | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.6&dist=debian%2Fwheezy) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.6&dist=debian%2Fwheezy) 11.6                               |
| Raspbian Jessie | [May 2017](https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-07-05/) | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_11.7&dist=debian%2Fjessie) 11.7                                                                                                                                        |
| Ubuntu 14.04    | [April 2019](https://ubuntu.com/info/release-end-of-life)                          | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_11.10&dist=ubuntu%2Ftrusty) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_11.10&dist=ubuntu%2Ftrusty) 11.10                            |
| OpenSUSE 42.3   | [July 2019](https://en.opensuse.org/Lifetime#Discontinued_distributions)           | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-12.1&dist=opensuse%2F42.3) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-12.1&dist=opensuse%2F42.3) 12.1                               |
| OpenSUSE 15.0   | [December 2019](https://en.opensuse.org/Lifetime#Discontinued_distributions)       | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce-12.5&dist=opensuse%2F15.0) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee-12.5&dist=opensuse%2F15.0) 12.5                               |
| Raspbian Stretch | [June 2020](https://downloads.raspberrypi.org/raspbian/images/raspbian-2019-04-09/)  | [GitLab CE](https://packages.gitlab.com/app/gitlab/raspberry-pi2/search?q=gitlab-ce_13.2&dist=raspbian%2Fstretch) 13.3                                                                                                                                  |
| Debian Jessie    | [June 2020](https://www.debian.org/News/2020/20200709)                               | [GitLab CE](https://packages.gitlab.com/app/gitlab/gitlab-ce/search?q=gitlab-ce_13.2&dist=debian%2Fjessie) / [GitLab EE](https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=gitlab-ee_13.2&dist=debian%2Fjessie) 13.3                            |

## Supported Operating Systems

GitLab officially supports LTS versions of operating systems. While OSs like
Ubuntu have a clear distinction between LTS and non-LTS versions, there are
other OSs, openSUSE for example, that don't follow the LTS concept. Hence to
avoid confusion, the official policy is that at any point of time, all the
operating systems supported by GitLab are listed in the [installation
page](https://about.gitlab.com/install/).

The following lists the currently supported OSs and their possible EOL dates.

| OS Version       | First supported GitLab version | OS EOL        | Details                                                      |
| ---------------- | ------------------------------ | ------------- | ------------------------------------------------------------ |
| CentOS 6         | GitLab CE / GitLab EE 7.10.0   | November 2020 | <https://wiki.centos.org/About/Product>                      |
| CentOS 7         | GitLab CE / GitLab EE 7.10.0   | June 2024     | <https://wiki.centos.org/About/Product>                      |
| CentOS 8         | GitLab CE / GitLab EE 12.8.1   | May 2029      | <https://wiki.centos.org/About/Product>                      |
| Debian 9         | GitLab CE / GitLab EE 9.3.0    | 2022          | <https://wiki.debian.org/DebianReleases#Production_Releases> |
| Debian 10        | GitLab CE / GitLab EE 12.2.0   | TBD           | <https://wiki.debian.org/DebianReleases#Production_Releases> |
| OpenSUSE 15.1    | GitLab CE / GitLab EE 12.4.0   | Nov 2020      | <https://en.opensuse.org/Lifetime>                           |
| SLES 12          | GitLab EE 9.0.0                | Oct 2027      | <https://www.suse.com/lifecycle/>                            |
| Ubuntu 16.04     | GitLab CE / GitLab EE 8.7.1    | April 2021    | <https://wiki.ubuntu.com/Releases>                           |
| Ubuntu 18.04     | GitLab CE / GitLab EE 10.7.0   | April 2023    | <https://wiki.ubuntu.com/Releases>                           |
| Ubuntu 20.04     | GitLab CE / GitLab EE 13.2.0   | April 2025    | <https://wiki.ubuntu.com/Releases>                           |
| Raspbian Buster  | GitLab CE 12.2.0               | 2022          | <https://wiki.debian.org/DebianReleases#Production_Releases> |
