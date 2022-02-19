# ATcms Cockroach

This repository contains the docker files for getting cockroach up and running in Fly.io, used for ATcms.

Code was shamelessly stollen from the fly-apps repository and an unmerged PR:

- <https://github.com/fly-apps/cockroachdb>
- <https://github.com/fly-apps/cockroachdb/pull/1>

## Updating

This repository has built in GitHub actions. This combined with Fly's awesome rolling deployments you should be safe for any updates. Simply make changes, make a PR, then merge into `main`. This will trigger a GitHub Action that will build the docker image, push it to the image repository, and then trigger a Fly.io deployment.

## GitHub Actions

This docker image is used in production _and in GitHub Actions_ for testing. Due to the way GitHub Actions works, it's not immediately obvious how to get this to work in an insecure configuration, so here is a short snippet of how that works:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    services:
      cockroach:
        image: ghcr.io/atcms-dev/atcms-cockroach:latest
        options: --entrypoint "/cockroach/start-insecure-local.sh"
        ports:
          - 26257:26257
          - 8080:8080
```

## Setting Up

1. The first step is to build a docker container for cockroach locally. This will give us access to all of the commands we need to run to generate certificates.

  ```sh
  $ docker build -t atcms-cockroach .
  ```

2. Next, we will start the docker image. All of the following commands should be executed in this container.

  ```sh
  $ docker run --rm -it -v $(pwd):/cockroach --entrypoint /bin/bash atcms-cockroach
  ```

3. Before we get started with generating certificates, we should setup a couple of things. First, we make the cockroach-certs directory to put everything, and secondly we set the `FLY_APP` environment variable to make some commands easier to run.

  ```sh
  $ mkdir cockroach-certs
  $ export FLY_APP="atcms-cockroach" # Update with fly app name
  ```

4. Next up we need to create the certificates. Enter these commands to generate the secrets.

  ```sh
  $ cockroach cert create-ca --certs-dir=/cockroach/cockroach-certs --ca-key=/cockroach/cockroach-certs/ca.key
  $ cockroach cert create-node --certs-dir=/cockroach/cockroach-certs --ca-key=/cockroach/cockroach-certs/ca.key 127.0.0.1 localhost $FLY_APP.internal "*.$FLY_APP.internal" "*.vm.$FLY_APP.internal" "*.nearest.of.$FLY_APP.internal" $FLY_APP.fly.dev
  ```

5. Finally we can **exit the docker container** and use `flyctl` to create the deployment. Run this command and follow the prompts. You shouldn't deploy this application yet.

  ```bash
  $ fly launch
  $ base64 ./cockroach-certs/ca.crt | fly secrets set DB_CA_CRT=-
  $ base64 ./cockroach-certs/node.crt | fly secrets set DB_NODE_CRT=-
  $ base64 ./cockroach-certs/node.key | fly secrets set DB_NODE_KEY=-
  ```

6. Past this point should be pretty regular fly commands. First, we create volumes for the database in each region we want.  For fault tollarance, Cockroach DB recommends running in a cluster of 3, 5, etc. More information you can read the [Cockroach DB documentation](https://www.cockroachlabs.com/docs/stable/recommended-production-settings.html#sizing).

  ```sh
  $ fly volumes create crdb_data --region <region> --size 10
  ```

7. (Optional) Then we set the VM size we want the database. Cockroach DB recommends at least 4gb of RAM, but I'm currently running on 512mb to see how far I can stretch a dollar. 256mb and you'll hit issues causing nodes to restart frequently. To each their own. It's rather easy to adjust after the fact as well.

  ```sh
  $ fly scale vm <size> --memory <memory_in_megabytes>
  ```

8. Then we do the first deployment.

  ```sh
  $ fly deploy
  ```

9. Initialize the cluster by using fly to ssh into the running container. This part is a little messy because we will need to generate certificate files for the root account.

  ```sh
  $ fly ssh console
  $ export FLY_APP="atcms-cockroach" # Update with fly app name
  $ mkdir cockroach-certs
  $ cockroach cert create-client --certs-dir=/cockroach/cockroach-certs --ca-key=/cockroach/cockroach-certs/ca.key root
  $ cockroach init --cluster-name=$FLY_APP --host=$FLY_APP.internal --certs-dir=/cockroach/cockroach-certs
  Cluster successfully initialized
  ```

  > **NOTE**: If you want to login to the root account, you will need to save the newly generated `client.root.crt` and `client.root.key` files.

10. Next up we will want to restart the current VM to clear out the generated root authentication files.

  ```sh
  $ fly vm restart <current running vm>
  ```

11. And lastly we can scale up the database cluster to the same number of volumes you created in step 6.

  ```sh
  $ fly scale count <number>
  ```

## Grafana

This example exports metrics for [Fly.io to scrape](https://fly.io/blog/hooking-up-fly-metrics/). You can import [CockroachDB's Grafana dashboards](https://github.com/cockroachdb/cockroach/tree/master/monitoring/grafana-dashboards) to see how your cluster is doing.

> **NOTE**: This is currently not working due to a bug with TLS metrics in Fly.io
> See https://community.fly.io/t/is-it-possible-to-tls-skip-verify-the-metrics-endpoint/4128 for more info
