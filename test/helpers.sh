#!/bin/bash

set -e -u

set -o pipefail

export TMPDIR_ROOT=$(mktemp -d /tmp/mvn-tests.XXXXXX)
trap "rm -rf $TMPDIR_ROOT" EXIT

if [ -d /opt/resource ]; then
  resource_dir=/opt/resource
else
  resource_dir=$(cd $(dirname $0)/../assets && pwd)
fi

run() {
  export TMPDIR=$(mktemp -d ${TMPDIR_ROOT}/mvn-tests.XXXXXX)

  echo -e 'running \e[33m'"$@"$'\e[0m...'
  eval "$@" 2>&1 | sed -e 's/^/  /g'
  echo ""
}

deploy_without_pom() {

  local url=$1
  local version=$2
  local username=$3
  local password=$4
  local src=$5

  local groupId=org.some.group
  local artifactId=your-artifact
  local packaging=jar
  local file=build-output/$artifactId-$version.$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/$file

  jq -n "{
    params: {
      file: $(echo $file | jq -R .),
      groupId: $(echo $groupId | jq -R .),
      artifactId: $(echo $artifactId | jq -R .),
      version: $(echo $version | jq -R .),
      packaging: $(echo $packaging | jq -R .)
    },
    source: {
      url: $(echo $url | jq -R .),
      username: $(echo $username | jq -R .),
      password: $(echo $password | jq -R .)
    }
  }" | $resource_dir/out "$src" | tee /dev/stderr
}

deploy_with_pom() {

  local url=$1
  local pom=$2
  local username=$3
  local password=$4
  local src=$5

  local artifactId=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='artifactId']/text()" $pom)
  local packaging=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='packaging']/text()" $pom)
  local version=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" $pom)

  local file=build-output/$artifactId-$version.$packaging

  # Mock the jar
  mkdir $src/build-output
  touch $src/$file

  jq -n "{
    params: {
      file: $(echo $file | jq -R .),
      pom: $(echo $pom | jq -R .)
    },
    source: {
      url: $(echo $url | jq -R .),
      username: $(echo $username | jq -R .),
      password: $(echo $password | jq -R .)
    }
  }" | $resource_dir/out "$src" | tee /dev/stderr
}
