FROM cockroachdb/cockroach:v21.2.10

ADD start-insecure-local.sh /cockroach/
ADD start-secure.sh /cockroach/

ENTRYPOINT ["/cockroach/start-secure.sh"]
