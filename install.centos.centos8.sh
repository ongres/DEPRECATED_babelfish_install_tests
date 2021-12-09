#!/bin/sh

export BABELFISH_CODE_USER="babelfish-compiler"
export BABELFISH_CODE_PATH="/opt/babelfish-code"
export INSTALLATION_PATH=/usr/local/pgsql-13.4
export PG_SRC="$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish"
export EXTENSIONS_SOURCE_CODE_PATH="$BABELFISH_CODE_PATH/babelfish_extensions"
export PG_CONFIG="$INSTALLATION_PATH/bin/pg_config"
export cmake=/usr/bin/cmake

if ! id "$BABELFISH_CODE_USER" > /dev/null
then
  useradd "$BABELFISH_CODE_USER" 
fi

dnf install -y unzip wget

mkdir -p "$BABELFISH_CODE_PATH"

cd "$BABELFISH_CODE_PATH" || exit 1

## Downloading latest babelfish engine source code
wget https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish/archive/refs/heads/BABEL_1_X_DEV__13_4.zip
  
unzip BABEL_1_X_DEV__13_4.zip 

mv postgresql_modified_for_babelfish-BABEL_1_X_DEV__13_4 "$PG_SRC"

rm BABEL_1_X_DEV__13_4.zip

chown -R "$BABELFISH_CODE_USER:$BABELFISH_CODE_USER" "$PG_SRC"

## Downloading latest babelbish extension source code

wget https://github.com/babelfish-for-postgresql/babelfish_extensions/archive/refs/heads/BABEL_1_X_DEV.zip

unzip BABEL_1_X_DEV.zip

mv babelfish_extensions-BABEL_1_X_DEV $EXTENSIONS_SOURCE_CODE_PATH

rm BABEL_1_X_DEV.zip

chown -R "$BABELFISH_CODE_USER:$BABELFISH_CODE_USER" "$EXTENSIONS_SOURCE_CODE_PATH"

dnf install -y gcc gcc-c++ kernel-devel make
dnf install -y bison flex libxml2-devel readline-devel zlib-devel
dnf --enablerepo=powertools install -y uuid-devel pkg-config openssl-devel
dnf install -y libicu-devel postgresql-devel perl

cd "$PG_SRC" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- ./configure CFLAGS="-ggdb" \
  --prefix="$INSTALLATION_PATH" \
  --enable-debug \
  --with-libxml \
  --with-uuid=ossp \
  --with-icu \
  --with-extra-version=" Babelfish for PostgreSQL"

mkdir -p "$INSTALLATION_PATH"

chown -R "$BABELFISH_CODE_USER:$BABELFISH_CODE_USER" "$INSTALLATION_PATH"

#Compilining babelfish engine
cd "$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish" || exit 1
runuser -u "$BABELFISH_CODE_USER" make # Compiles the Babefish for PostgreSQL engine

cd "$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish/contrib" || exit 1
runuser -u "$BABELFISH_CODE_USER" make # Compiles the PostgreSQL default extensions

cd "$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish" || exit 1

runuser -u "$BABELFISH_CODE_USER" make install # Installs the Babelfish for PostgreSQL engine
cd "$BABELFISH_CODE_PATH/postgresql_modified_for_babelfish/contrib" || exit 1

runuser -u "$BABELFISH_CODE_USER" make install # Installs the PostgreSQL default extensions

dnf install -y java unzip curl git
dnf install -y cmake libuuid-devel

# Dowloads the compressed Antlr4 Runtime sources on /opt/antlr4-cpp-runtime-4.9.2-source.zip 
curl https://www.antlr.org/download/antlr4-cpp-runtime-4.9.2-source.zip \
  --output /opt/antlr4-cpp-runtime-4.9.2-source.zip 

# Uncompress the source into /opt/antlr4
unzip -d /opt/antlr4 /opt/antlr4-cpp-runtime-4.9.2-source.zip

mkdir /opt/antlr4/build 
cd /opt/antlr4/build || exit 1

# Generates the make files for the build
cmake .. -DANTLR_JAR_LOCATION="$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-4.9.2-complete.jar" \
         -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True
# Compiles and install
make
make install

cp /usr/local/lib/libantlr4-runtime.so.4.9.2 "$INSTALLATION_PATH/lib"

# Install babelfishpg_money extension
cd "$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_money" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- make
runuser -u "$BABELFISH_CODE_USER" -- make install

# Install babelfishpg_common extension
cd "$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_common" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- make
runuser -u "$BABELFISH_CODE_USER" -- make install

# Install babelfishpg_tds extension
cd "$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tds" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- make
runuser -u "$BABELFISH_CODE_USER" -- make install

# Installs the babelfishpg_tsql extension
cd "$EXTENSIONS_SOURCE_CODE_PATH/contrib/babelfishpg_tsql" || exit 1
runuser -u "$BABELFISH_CODE_USER" -- make
runuser -u "$BABELFISH_CODE_USER" -- make install

mkdir -p /usr/local/pgsql/data

useradd postgres

chown -R postgres:postgres "$INSTALLATION_PATH"
chown -R postgres:postgres /usr/local/pgsql/data

runuser -u "postgres" -- "$INSTALLATION_PATH/bin/initdb" -D /usr/local/pgsql/data


echo "listen_addresses = '*'" >> /usr/local/pgsql/data/postgresql.conf
echo "shared_preload_libraries = 'babelfishpg_tds'" >> /usr/local/pgsql/data/postgresql.conf

cd "$INSTALLATION_PATH" || exit 1

runuser -u "postgres" -- "$INSTALLATION_PATH/bin/pg_ctl" -D /usr/local/pgsql/data start