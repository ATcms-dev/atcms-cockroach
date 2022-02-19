FROM cockroachdb/cockroach:v21.2.5

RUN microdnf install bind-utils

ADD start.sh /cockroach/

ENTRYPOINT ["/cockroach/start.sh"]
