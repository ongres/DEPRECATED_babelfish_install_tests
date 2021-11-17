FROM ubuntu:20.04
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential flex libxml2-dev bison libreadline-dev zlib1g-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends uuid-dev pkg-config libossp-uuid-dev libssl-dev 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends icu-devtools
RUN mkdir /code
RUN mkdir /usr/local/pgsql-13.4

COPY 'postgresql_modified_for_babelfish' '/code/postgresql_modified_for_babelfish'
WORKDIR /code/postgresql_modified_for_babelfish

RUN ./configure \
  --prefix=/usr/local/pgsql-13.4 \
  --enable-debug CFLAGS="-ggdb" \
  --with-uuid=ossp \
  --with-icu \
  --with-libxml \
  --with-extra-version=" Babelfish for PostgreSQL"

RUN make -j 3

WORKDIR /code/postgresql_modified_for_babelfish/contrib
RUN make -j 3

WORKDIR /code/postgresql_modified_for_babelfish
RUN make install

WORKDIR /code/postgresql_modified_for_babelfish/contrib
RUN make install

COPY 'babelfish_extensions' '/code/babelfish_extensions'

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openjdk-8-jre unzip libutfcpp-dev curl git cmake

RUN cp /code/babelfish_extensions/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-4.9.2-complete.jar /usr/local/lib

RUN curl https://www.antlr.org/download/antlr4-cpp-runtime-4.9.2-source.zip \
   --output /opt/antlr4-cpp-runtime-4.9.2-source.zip 

RUN unzip -d /opt/antlr4 /opt/antlr4-cpp-runtime-4.9.2-source.zip

RUN mkdir /opt/antlr4/build 
WORKDIR /opt/antlr4/build

RUN cmake .. -DANTLR_JAR_LOCATION="/usr/local/lib/antlr-4.9.2-complete.jar" \
         -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_DEMO=True

RUN make
RUN make install

RUN cp /usr/local/lib/libantlr4-runtime.so.4.9.2 "/usr/local/pgsql-13.4/lib"

ENV PG_CONFIG=/usr/local/pgsql-13.4/bin/pg_config
ENV PG_SRC=/code/postgresql_modified_for_babelfish
ENV cmake=/usr/bin/cmake

WORKDIR /code/babelfish_extensions/contrib/babelfishpg_money

RUN make
RUN make install

WORKDIR /code/babelfish_extensions/contrib/babelfishpg_common
RUN make  
RUN make install

WORKDIR /code/babelfish_extensions/contrib/babelfishpg_tds
RUN make
RUN make install

WORKDIR /code/babelfish_extensions/contrib/babelfishpg_tsql
RUN make
RUN make install

RUN mkdir /usr/local/pgsql/
RUN mkdir /usr/local/pgsql/data

RUN useradd postgres
RUN chown -R postgres:postgres /usr/local/pgsql-13.4/
RUN chown -R postgres:postgres /usr/local/pgsql/data

USER postgres
RUN /usr/local/pgsql-13.4/bin/initdb -D /usr/local/pgsql/data

RUN echo "listen_addresses = '*'" >> /usr/local/pgsql/data/postgresql.conf
RUN echo "shared_preload_libraries = 'babelfishpg_tds'" >> /usr/local/pgsql/data/postgresql.conf

EXPOSE 5432
EXPOSE 1433

USER root

RUN set -ex ; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list && \
    apt update && ACCEPT_EULA=Y apt install -y mssql-tools unixodbc-dev

USER postgres

ENV PATH="/usr/local/pgsql-13.4/bin:/opt/mssql-tools/bin/:${PATH}"

WORKDIR /usr/local/pgsql-13.4/bin

CMD [ "/usr/local/pgsql-13.4/bin/postgres", "-D", "/usr/local/pgsql/data" ]