FROM cockroachdb/cockroach:v21.2.8

ADD start-insecure-local.sh /cockroach/
ADD start-secure.sh /cockroach/

ENTRYPOINT ["/cockroach/start-secure.sh"]
