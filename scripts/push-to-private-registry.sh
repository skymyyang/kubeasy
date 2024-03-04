#!/bin/bash
# ./push-to-private-registry.sh -h 172.16.2.11 -r infra -u admin -p admin
help() {
  echo "Usage:"
  echo "$0 -h host -u username -p password [-r repository ]"
  echo "Description:"
  echo "host, harbor url."
  echo "repository, harbor repository name."
  echo "username, harbor username."
  echo "password, harbor password."
  exit -1
}

while getopts "h:r:u:p:" opt_name; do
  case $opt_name in
  h)
    export host=$OPTARG
    ;;
  r)
    export repo=$OPTARG
    ;;
  u)
    export username=$OPTARG
    ;;
  p)
    export password=$OPTARG
    ;;
  ?)
    help
    ;;
  esac
done

set -e
for r in $(curl -s 127.0.0.1:5000/v2/_catalog | jq -r .repositories[]); do
  for t in $(curl -s 127.0.0.1:5000/v2/${r}/tags/list | jq -r .tags[]); do
    if [ "$repo" == "" ]; then
      export toHarbor=${host}/${r}:${t}
    else
      export toHarbor=${host}/${repo}/${r}:${t}
    fi
    echo "[sync] 127.0.0.1:5000/${r}:${t}"
    skopeo copy --src-tls-verify=false --dest-username=${username} --dest-password=${password} --dest-tls-verify=false docker://127.0.0.1:5000/${r}:${t} docker://${toHarbor}
  done
done
