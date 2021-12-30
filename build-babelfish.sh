#!/bin/sh

build_docker(){
  python dockerfile-templater.py "$1"
  docker build \
    -t "babelfish:$1" \
    -f "distros/$1/Dockerfile" \
  . > "output/$1/$1.out" 2>&1
}

add_to_report() {
  DISTRO=$1
  STATUS=$2
  cat << EOF >> report.md
| $DISTRO | $STATUS |
EOF
}

test_create_extension(){
  DISTRO=$1

  docker run --rm -d --name babelfish "babelfish:$DISTRO"
  sleep 5
  run_in_babelfish_container "CREATE USER babelfish_user WITH CREATEDB CREATEROLE PASSWORD 'babelfish' INHERIT;"
  run_in_babelfish_container "CREATE DATABASE demo OWNER babelfish_user;"
  run_in_babelfish_container "ALTER SYSTEM SET babelfishpg_tsql.database_name = 'demo'; SELECT pg_reload_conf();"
  run_in_babelfish_container "ALTER DATABASE demo SET babelfishpg_tsql.migration_mode = 'single-db';"
  run_in_babelfish_container 'CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE;' "demo"
  run_in_babelfish_container "CALL SYS.INITIALIZE_BABELFISH('babelfish_user');" "demo"
  docker stop babelfish
}

run_in_babelfish_container(){  
  STATEMENT=$1
  if [ -z "${2+x}" ]
  then
    docker exec babelfish /usr/local/pgsql-13.4/bin/psql -c "$STATEMENT"
  else
    docker exec babelfish /usr/local/pgsql-13.4/bin/psql -c "$STATEMENT" -d "$2"
  fi
}

generate_quickinstall_script(){
  DISTRO=$1
  mkdir "output/${DISTRO}/quickinstall"
  python quick-start-templater.py "$DISTRO"
  cp quick-install.sh "output/${DISTRO}/quickinstall.sh"
}

build_quickstart_container(){
  DISTRO=$1
  BASE_CONTAINER=$(echo "$DISTRO" | sed -e 's/\./:/ ')
  rm -rf tmp
  mkdir tmp
  cat << EOF > tmp/entrypoint.sh
#!/bin/sh
sh prerequisites.sh
sh install.sh
EOF
  cat << EOF > tmp/Dockerfile
FROM $BASE_CONTAINER
ENV TZ="Europe/Madrid"
ENV DEBIAN_FRONTEND=noninteractive
COPY 'output/${DISTRO}/quickinstall/prerequisites.sh' '/prerequisites.sh'
COPY 'output/${DISTRO}/quickinstall.sh' '/install.sh'
COPY 'tmp/entrypoint.sh' '/entrypoint.sh'
CMD ["sh", "-e", "/entrypoint.sh"]
EOF

  docker build -t "babelfish:$DISTRO" -f tmp/Dockerfile . 
}

run_quickstart_container(){
  DISTRO=$1
  docker run --rm --name babelfish "babelfish:$DISTRO"
}

cat << EOF > report.md
## Babelfish Docker images builed 
| Distro | Status |
| ------ | ------ |
EOF

rm -rf output
mkdir output
find distros -mindepth 1 -maxdepth 1 -printf "%f\n" | while read -r distro
do 
  echo "Building docker image for $distro"

  mkdir "output/$distro"

  if build_docker "$distro"
  then
    echo "Testing extension creation for $distro"
    if test_create_extension "$distro" > "output/$distro/$distro.out" 2>&1
    then 
      generate_quickinstall_script "$distro"
      build_quickstart_container "$distro" > /dev/null 2>&1
      echo "Testing quick install script for $distro"
      if run_quickstart_container "$distro" > "output/$distro/$distro.out" 2>&1
      then 
        add_to_report "$distro" "OK"
        echo "Generating installation documentation for $distro"
        python doc-templater.py "$distro"
      else
        add_to_report "$distro" "QUICK INSTALL FAILED"
      fi      
    else
      add_to_report "$distro" "CREATE EXTENSION FAILED"
    fi
  else
    add_to_report "$distro" "BUILD FAILED"
  fi

done
