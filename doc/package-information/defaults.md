# Package defaults

Unless configuration is specified in the `/etc/gitlab/gitlab.rb` file,
the package will assume the defaults as noted below.

## Ports

See the table below for the list of ports that the omnibus-gitlab assigns
by default:

| Component        | On by default | Communicates via | Alternative | Connection port                        |
| :--------------: | :------------:| :--------------: | :---------: | :------------------------------------: |
| GitLab Rails     | Yes           | Port             | X           | 80 or 443                              |
| GitLab Shell     | Yes           | Port             | X           | 22                                     |
| PostgreSQL       | Yes           | Socket           | Port (5432) | X                                      |
| Redis            | Yes           | Socket           | Port (6379) | X                                      |
| Unicorn          | Yes           | Socket           | Port (8080) | X                                      |
| GitLab Workhorse | Yes           | Socket           | Port (8181) | X                                      |
| Incoming email   | No            | Port             | X           | 143                                    |
| Elastic search   | No            | Port             | X           | 9200                                   |
| GitLab Pages     | No            | Port             | X           | 80 or 443                              |
| GitLab Registry  | No            | Port             | X           | 80 or 443                              |
| GitLab Registry  | No            | Port             | X           | 5000                                   |
| LDAP             | No            | Port             | X           | Depends on the component configuration |
| Kerberos         | No            | Port             | X           | 8443 or 8088                           |
| Omniauth         | No            | Port             | X           | Depends on the component configuration |
| SMTP             | No            | Port             | X           | 465                                    |
| Remote syslog    | No            | Port             | X           | 514                                    |
| Mattermost       | No            | Port             | X           | 8065                                   |
| Mattermost       | No            | Port             | X           | 80 or 443                              |

Legend:

* `Component` - Name of the component.
* `On by default` - Is the component running by default.
* `Communicates via` - How the component talks with the other components.
* `Alternative` - If it is possible to configure the component to use different type of communication. The type is listed with default port used in that case.
* `Connection port` - Port on which the component communicates.
