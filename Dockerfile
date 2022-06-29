FROM cockroachdb/cockroach:v22.1.2

ADD start-insecure-local.sh /cockroach/
ADD start-secure.sh /cockroach/

ENTRYPOINT ["/cockroach/start-secure.sh"]
