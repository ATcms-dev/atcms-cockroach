FROM cockroachdb/cockroach:v21.2.5

RUN microdnf install bind-utils

ADD start-insecure-local.sh /cockroach/
ADD start-secure.sh /cockroach/

ENTRYPOINT ["/cockroach/start-secure.sh"]
