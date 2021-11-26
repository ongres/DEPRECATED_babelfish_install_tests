#!/bin/sh

build_docker(){
  python dockerfile-templater.py "$1"
  docker build \
    -t "babelfish:$1" \
    -f "distros/$1/Dockerfile" \
  . > "$1.out" 2>&1
}

add_to_report() {
  DISTRO=$1
  STATUS=$2
  cat << EOF >> report.md
| $DISTRO | $STATUS |
EOF
}

cat << EOF > report.md
## Babelfish Docker images builed 
| Distro | Status |
| ------ | ------ |
EOF

find distros -mindepth 1 -maxdepth 1 -printf "%f\n" | while read -r distro
do 
  echo "Building docker image for $distro"

  if build_docker "$distro"
  then
    add_to_report "$distro" "OK"
  else
    add_to_report "$distro" "FAILED"
  fi

done
