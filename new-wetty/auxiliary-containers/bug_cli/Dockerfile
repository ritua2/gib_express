FROM frolvlad/alpine-gcc:latest



COPY aux_functions.hh   /bug_cli/aux_functions.hh
COPY bug_db_cli.cc      /bug_cli/bug_db_cli.cc



# Requires git to get the most recent evrsion of the bug database
RUN apk add git g++ libstdc++ &&\
    mkdir -p /shared/data &&\
    cd /shared/data && git clone https://github.com/ritua2/IPT &&\
    mv IPT/bug_database_with_UI_iteration0/Bug_Collection . &&\
    rm -rf IPT &&\
    g++ -std=c++11 -static /bug_cli/bug_db_cli.cc -o /shared/bug_db_cli &&\
    # Deletes git, gcc, g++ in order to reduce the space of the image
    apk del git pcre2 expat libcurl nghttp2-libs
