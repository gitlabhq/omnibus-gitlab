# Asset proxy with Camo server

GitLab can be configured to use an [asset proxy server](https://docs.gitlab.com/ee/security/asset_proxy)
when requesting external images/videos in issues, comments, etc. This helps
ensure that malicious images do not expose the user's IP address when they are fetched.

## Installation

A Camo server is used to act as the proxy. We currently recommend using
[cactus/go-camo](https://github.com/cactus/go-camo#how-it-works) as it supports proxying video and
is more configurable.

To install a Camo server as an asset proxy:

1. Deploy a `go-camo` server. Helpful instructions can be found in
   [building catus/go-camo](https://github.com/cactus/go-camo#building).

1. Make sure your instance of GitLab is running, and that you have created a private API token.
   Using the API, configure the [asset proxy settings](https://docs.gitlab.com/ee/security/asset_proxy)
   on your GitLab instance. For example:

    ```sh
    curl -X "PUT" "https://gitlab.example.com/api/v4/application/settings?\
    asset_proxy_enabled=true&\
    asset_proxy_url=https://proxy.gitlab.example.com&\
    asset_proxy_secret_key=somekey" \
    -H 'PRIVATE-TOKEN: my-private-token'
    ```

1. Restart the server for the changes to take effect. Each time you change any values for the asset
   proxy, you need to restart the server.

## Usage

Once the Camo server is running and you've enabled the GitLab settings, any image or video that
references an external source will get proxied to the Camo server. For example, the following
Markdown image:

```markdown
![logo](https://about.gitlab.com/images/press/logo/jpg/gitlab-icon-rgb.jpg)
```

The above Markdown would have a source link similar to the following:

```text
http://proxy.gitlab.example.com/f9dd2b40157757eb82afeedbf1290ffb67a3aeeb/68747470733a2f2f61626f75742e6769746c61622e636f6d2f696d616765732f70726573732f6c6f676f2f6a70672f6769746c61622d69636f6e2d7267622e6a7067
```
