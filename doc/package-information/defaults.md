# Package defaults

Unless configuration is specified in the `/etc/gitlab/gitlab.rb` file,
the package will assume the defaults as noted below.

## Ports

See the table below for the list of ports that the omnibus-gitlab assigns
by default:

| Component        | On by default | Communicates via | Alternative | Internal communication port | External communication port |
| :--------------: | :------------:| :--------------: | :---------: | :-------------------------: | :-------------------------: |
| GitLab Rails     | Yes           | Port             | X           |         X                   | 80 or 443                   |
| GitLab Shell     | Yes           | Port             | X           |         X                   | 22                          |
| PostgreSQL       | Yes           | Socket           | Port        |         5432                | X                           |
| Redis            | Yes           | Socket           | Port        |         6379                | X                           |
| Unicorn          | Yes           | Socket           | Port        |         8080                | X                           |
| GitLab Workhorse | Yes           | Socket           | Port        |         8181                | X                           |
| Incoming email   | No            | Port             | X           |         143                 | X                           |
| Elastic search   | No            | Port             | X           |         9200                | X                           |
| GitLab Pages     | No            | Port             | X           |         X                   | 80 or 443                   |
| GitLab Registry  | No            | Port             | X           |         X                   | 80 or 443                   |
| GitLab Registry  | No            | Port             | X           |         5000                | X                           |
| LDAP             | No            | Port             | X           | Depends on the component    | X                           |
| Kerberos         | No            | Port             | X           | 8443 or 8088                | X                           |
| Omniauth         | No            | Port             | X           | Depends on the component    | X                           |
| SMTP             | No            | Port             | X           |         465                 | X                           |
| Remote syslog    | No            | Port             | X           |         514                 | X                           |
| Mattermost       | No            | Port             | X           |         8065                | X                           |
| Mattermost       | No            | Port             | X           |         X                   | 80 or 443                   |

Legend:

`Component` - Name of the component
`On by default` - Is the component running by default
`Communicates via` - How the component talks with the other components
`Alternative` - If it is possible to configure the component to use different type of communication and the type
`Internal communication port` - Valid only if the component communicates via a port. This port does not need to be accessible to the
outside world but if the component it communicates with is on a different machine, the port needs to be accessible.
`External communication port` - Valid only if the component communicates via a port. This is the connection point for the end user.
