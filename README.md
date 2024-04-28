# Shell functions to list tags and supported CPU architectures for Docker Hub images

`search-dockerhub.sh` defines two shell-functions, `docker-list-tags` and `docker-inspect-architecture`.

## `docker-list-tags`
### Usage

```bash
docker-list-tags-usage [-j|--json] [-n|--with-name] [<NAMESPACE>/]<IMAGE>
```

#### Argument Specifications

* `<NAMESPACE>`  : Docker Hub namespace or username (default: `library`)
* `<IMAGE>`      : Docker image name (mandatory)

#### Options

* `-j`, `--json`      : Output the result in JSON format
* `-n`, `--with-name` : Include the image name in the output
* `-h`, `--help`      : Show this help message and exit

### Examples

```bash
# List all tags for 'library/ubuntu'
docker-list-tags ubuntu
```
    


```bash
# List all tags for 'mysql/mysql-server' as JSON
docker-list-tags -j mysql/mysql-server
```

## `docker-inspect-architecture`

### Usage

```bash
docker-inspect-architecture [<NAMESPACE>/]<IMAGE>[:<TAG>]
```

#### Argument Specifications

* `<NAMESPACE>`  : Docker Hub namespace or username (default: `library`)

* `<IMAGE>`      : Image name (mandatory)

* `<TAG>`        : Tag name (default: `latest`)

### Examples
  ```bash
# Inspect architectures of library/ubuntu:latest
docker-inspect-architecture ubuntu
```

```bash
# Inspect architectures of library/ubuntu:22.04
docker-inspect-architecture ubuntu:22.04
```

```bash
# Inspect architectures of mysql/mysql-server:latest
docker-inspect-architecture mysql/mysql-server
```

```bash
# Inspect architectures of mysql/mysql-server:8.0
docker-inspect-architecture mysql/mysql-server:8.0
```

# Requirements

* Bash or Zsh
* curl
* jq

# License

[MIT License](https://github.com/doraTeX/search-dockerhub/blob/main/LICENSE)
