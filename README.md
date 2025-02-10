<p align="center">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="./images/logo_dark.svg" width="300">
        <source media="(prefers-color-scheme: light)" srcset="./images/logo_light.svg" width="300">
        <img src="./images/logo_light.svg" width="300">
    </picture>
</p>

<p align="center">
    <strong>A getting started guide to self-hosting <a href="https://wanderer.ltd/news/community-edition">Wanderer Community Edition</a></strong>
</p>

<!-- TODO latest version, current version, requirements -->

**Contact**:

- For release announcements please go to [GitHub releases.](https://github.com/wanderer-industries/wanderer/releases)
- For a question or advice please go to [GitHub discussions.](https://github.com/orgs/wanderer-industries/discussions/4)

---

<p align="center">
    <a href="#install">Install</a> &bull;
    <a href="#upgrade">Upgrade</a> &bull;
    <a href="#configure">Configure</a> &bull;
    <a href="#faq">FAQ</a>
</p>

---

## Install

[Wanderer Community Edition (or CE for short)](https://wanderer.ltd/news/community-edition) is designed to be self-hosted through [Docker.](https://docs.docker.com/guides/get-started/) You don't have to be a Docker expert to launch your own instance, but you should have a basic understanding of the command-line and networking to successfully set it up.

### Requirements

The only thing you need to install Wanderer CE is a server with Docker. The server must have a CPU with x86_64 or arm64 architecture and support for SSE 4.2 or equivalent NEON instructions. We recommend using a minimum of 1GB of RAM but the requirements will depend on your site traffic.

We've tested this on [Linode](https://www.linode.com/) but any hosting provider works. If your server doesn't come with Docker pre-installed, you can follow [their docs](https://docs.docker.com/get-docker/) to install it.

To make your Wanderer CE instance accessible on a (sub)domain, you also need to be able to edit your DNS. Wanderer CE isn't currently designed for subfolder installations.

### Quick start

To get started quickly, clone the [wanderer-industries/community-edition](https://github.com/wanderer-industries/community-edition) repo. It has everything you need to boot up your own Wanderer CE server.

<sub><kbd>console</kbd></sub>
```console
$ git clone https://github.com/wanderer-industries/community-edition hosting
Cloning into 'community-edition'...
remote: Enumerating objects: 280, done.
remote: Counting objects: 100% (146/146), done.
remote: Compressing objects: 100% (74/74), done.
remote: Total 280 (delta 106), reused 86 (delta 71), pack-reused 134
Receiving objects: 100% (280/280), 69.44 KiB | 7.71 MiB/s, done.
Resolving deltas: 100% (136/136), done.
$ ls hosting
README.md           docker-compose.yml  images/             wanderer-conf.env  reverse-proxy/
```

In the downloaded directory you'll find two important files:

- [docker-compose.yml](./docker-compose.yml) — installs and orchestrates networking between your Wanderer CE server and Postgres database.
- [wanderer-conf.env](./wanderer-conf.env) — configures the Wanderer server itself. Full configuration options are documented [below.](#configure)

Right now the latter looks like this:

<sub><kbd>[wanderer-conf.env](./wanderer-conf.env)</kbd></sub>
```env
WEB_APP_URL=replace-me
SECRET_KEY_BASE=replace-me
CLOAK_KEY=replace-me
EVE_CLIENT_ID=replace-me
EVE_CLIENT_SECRET=replace-me
```

Let's do as it asks and populate these required environment variables with our own values.

#### EVE API keys

The following screenshot-annotated guide shows how to do it all in an easy way: just follow the Google-colored arrows!

---

Here's the outline of what we'll do:

<!-- no toc -->
- [Eve Online Developer portal](#eve-online-developer-portal)
- [Create new application](#create-new-application)

---

#### Eve Online Developer portal

* Go to [Eve Online Developer portal](https://developers.eveonline.com/)

#### Create new Application

* Select "MANAGE APPLICATIONS" → "CREATE NEW APPLICATION"
<img src="./images/manage-applications.png">
<img src="./images/create-application.png">

* Choose a name for your application (e.g. "Wanderer Production")
<img src="./images/application-name.png">

* Enter a Description for this application
* Set "CONNECTION TYPE" to "Authentication & API Access"
<img src="./images/connection-type.png">

* Add the following "PERMISSIONS":
  * `esi-location.read_location.v1`
  * `esi-location.read_ship_type.v1`
  * `esi-search.search_structures.v1`
  * `esi-ui.write_waypoint.v1`
  * `esi-location.read_online.v1`

<img src="./images/permissions.png">

* Set your "CALLBACK URL" to `https://[YOUR_DOMAIN]/auth/eve/callback`</br></br>

**Note:** The callback URL must be a valid URL and must be accessible from the internet. If you plan to run it insecure you can use `http://[YOUR_DOMAIN]/auth/eve/callback` or `http://localhost:8000/auth/eve/callback` to run it on locally on your machine.

Once the aplication is created, you can find the **Client ID** and **Secret Key** in the Application Settings page.

<img src="./images/application-settings.png">

<details>

And just like that, you have a new application registered!

</details>

Update the [wanderer-conf.env](./wanderer-conf.env) with the Client ID and Secret Key:

<sub><kbd>wanderer-conf.env</kbd></sub>
```diff
- EVE_CLIENT_ID=replace-me
+ EVE_CLIENT_ID=dsxvbn4jxDd11az2QpsX5B8O+llxjQ6SJE2i1Bzx56I=
- EVE_CLIENT_SECRET=replace-me
+ EVE_CLIENT_SECRET=GLVzqfTUXti7FLBd7aflXeQDdwCj6Cz
```

#### Required configuration

First we generate the [secret key base](#secret_key_base) and [Cloak vault key](#cloak_vault_key) using OpenSSL:

<sub><kbd>console</kbd></sub>
```console
$ openssl rand -base64 48
GLVzDZW18FzuS2gMcmBRVhwgd4Gu7YmSl/k/TqfTUXti7FLBd7aflXeQDdwCj6Cz
$ openssl rand -base64 32
dsxvbn5jxDd16az2QpsX5B8O+llxjQ6SJE2i5Bzx56I=
```

And then we decide on the [base URL](#base_url) where the instance would be accessible:

<sub><kbd>wanderer-conf.env</kbd></sub>
```diff
- WEB_APP_URL=replace-me
+ WEB_APP_URL=http://localhost:8000
- SECRET_KEY_BASE=replace-me
+ SECRET_KEY_BASE=GLVzDZW18FzuS2gMcmBRVhwgd4Gu7YmSl/k/TqfTUXti7FLBd7aflXeQDdwCj6Cz
- CLOAK_KEY=replace-me
+ CLOAK_KEY=dsxvbn5jxDd16az2QpsX5B8O+llxjQ6SJE2i5Bzx56I=
```

Now we can start everything together by running:

<sub><kbd>console</kbd></sub>
```console
$ docker compose -f docker-compose.yml up -d
[+] Running 19/19
 ✔ wanderer_db 9 layers [⣿⣿⣿⣿⣿⣿⣿]          Pulled
 ✔ wanderer 7 layers [⣿⣿⣿⣿⣿⣿⣿]             Pulled
[+] Running 5/5
 ✔ Network hosting_default                  Created
 ✔ Container hosting-wanderer_db-1         Started
 ✔ Container hosting-wanderer-1            Started
```

[The Wanderer instance](http://localhost:8000) will take some time to start. It will create the databases, run the migrations, and populate the database with the initial data.
After about fifteen seconds you should be able to access your instance at the WEB_APP_URL and see the welcome screen.

<img src="./images/welcome.png">

#### Authorize your first character

Before continue setting up Wanderer, you need to authorize your first character. This is required to get the character's data from the Eve Online API.

So you can configure Wanderer administrator account with your registered character ID later.

#### Initialize EVE Online Data

Wanderer uses the Eve Online Data to get information about the ships, systems, and additional information. This data is used to provide the information for the search results.

* Go to Wanderer Admin page at `http://localhost:8000/admin`</br></br>
* Click on "Update EVE DB Data" button

<img src="./images/update-eve-db-data.png">

* Wait for the data to be initialized

> [!NOTE]
> This step can take some time to complete. The data is cached in the database and will be used for the search results.

#### Caddy

We can start our instance now but the requests would be served over HTTP. Not cool! Let's configure [Caddy](https://caddyserver.com) to enable HTTPS.


> [!TIP]
> For other reverse-proxy setups please see [reverse-proxy](./reverse-proxy) docs.

<details>
<summary>Don't need reverse proxy?</summary>

---

If you're **opting out** of a reverse proxy and HTTPS, you'll need to adjust the Wanderer service [configuration](./docker-compose.yml#L38) to ensure it's not limited to localhost (127.0.0.1). This change allows the service to be accessible from any network interface:

<sub><kbd>[docker-compose.yml](./docker-compose.yml#L38)</kbd></sub>
```diff
wanderer:
  ports:
-   - 127.0.0.1:8000:8000
+   - 8000:8000
```

---

</details>

First we need to point DNS records for our base URL to the IP address of the instance. This is needed for Caddy to issue the TLS certificates.

Then we need to let Caddy know the domain name for which to issue the TLS certificate and the service to redirect the requests to.

<sub><kbd>[reverse-proxy/docker-compose.caddy-gen.yml](./reverse-proxy/docker-compose.caddy-gen.yml)</kbd></sub>
```diff
  services:
    caddy-gen:
-     command: caddy reverse-proxy --from example.com --to :8000 # change 'example.com' to your domain name
+     command: caddy reverse-proxy --from wanderer.example.com --to :8000

  ...

  wanderer:
    labels:
-     virtual.host: "example.com" # change to your domain name
+     virtual.host: "wanderer.example.com"
      virtual.port: "8000"
-     virtual.tls-email: "admin@example.com" # change to your email
+     virtual.tls-email: "admin@wanderer.example.com"
```

Finally we need to update the base URL to use HTTPS scheme.

<sub><kbd>wanderer-conf.env</kbd></sub>
```diff
- WEB_APP_URL=http://wanderer.example.com
+ WEB_APP_URL=https://wanderer.example.com
  SECRET_KEY_BASE=GLVzDZW18FzuS2gMcmBRVhwgd4Gu7YmSl/k/TqfTUXti7FLBd7aflXeQDdwCj6Cz
  CLOAK_KEY=dsxvbn5jxDd16az2QpsX5B8O+llxjQ6SJE2i5Bzx56I=
```

Now we can start everything together.

#### Launch

<sub><kbd>console</kbd></sub>
```console
$ docker compose -f docker-compose.yml -f reverse-proxy/docker-compose.caddy-gen.yml up -d
[+] Running 19/19
 ✔ wanderer_db 9 layers [⣿⣿⣿⣿⣿⣿⣿]          Pulled
 ✔ wanderer 7 layers [⣿⣿⣿⣿⣿⣿⣿]             Pulled
 ✔ caddy-gen 8 layers [⣿⣿⣿⣿⣿⣿⣿⣿]            Pulled
[+] Running 5/5
 ✔ Network hosting_default                  Created
 ✔ Container hosting-wanderer_db-1         Started
 ✔ Container hosting-wanderer-1            Started
 ✔ Container caddy-gen                      Started
```

It takes some time to start PostgreSQL, create the databases, and run the migrations. After about fifteen seconds you should be able to access your instance at the base URL and see the welcome screen.

> [!TIP]
> If something feels off, make sure to check out the logs with <kbd>docker compose logs</kbd> and start a [GitHub discussion.](https://github.com/orgs/wanderer-industries/discussions/4)

🎉 Happy hosting! 🚀

Next we'll go over how to upgrade the instance when a new release comes out and more things to configure!

## Upgrade

This section outlines the general steps and explains the versioning.

Try to keep your instance up to date with the latest version. If you're using Docker Compose, you can use the `docker compose pull` command to update your containers and then run `docker compose up -d` to start them again.

**Note:** You should stop docker contaners before upgrading to avoid data loss. If you're using Docker Compose, you can use the `docker compose stop` or `docker compose down` commands to stop your containers.

You can also use the script located at **./scripts/deploy_wanderer.sh**

### Version management

Wanderer CE follows [semantic versioning:](https://semver.org/) `MAJOR.MINOR.PATCH`

You can find available Wanderer versions on [Docker Hub tags.](https://hub.docker.com/repository/docker/wandererltd/community-edition/tags) The default `latest` tag refers to the latest stable release tag. You can also pin your version:

- <kbd>wandererltd/community-edition:v1.0.0</kbd>

None of the functionality is backported to older versions. If you wish to get the latest bug fixes and security updates you need to upgrade to a newer version.

New versions are published on [the releases page](https://github.com/wanderer-industries/wanderer/releases) and their changes are documented in our [Changelog.](https://github.com/wanderer-industries/wanderer/blob/main/CHANGELOG.md) Please note that database schema changes require running migrations when you're upgrading. However, we consider the schema as an internal API and therefore schema changes aren't considered a breaking change.

We recommend to pin the major version instead of using `latest`. Either way the general flow for upgrading between minor version would look like this:

<sub><kbd>console</kbd></sub>
```console
$ cd hosting # or wherever you cloned this repo
$ docker compose stop wanderer
[+] Running 1/1
 ✔ Container hosting-wanderer-1  Stopped
$ docker compose rm wanderer
? Going to remove hosting-wanderer-1 Yes
[+] Running 1/0
 ✔ Container hosting-wanderer-1  Removed
$ docker compose -f docker-compose.yml -f reverse-proxy/docker-compose.caddy-gen.yml up -d
[+] Running 8/8
 ✔ wanderer 7 layers [⣿⣿⣿⣿⣿⣿⣿]      0B/0B      Pulled 6.4s
   ✔ 96526aa774ef Pull complete    0.4s
   ✔ 93631fa7258d Pull complete    0.6s
   ✔ 06afbc05374b Pull complete    1.6s
   ✔ 7ddeeadcce1e Pull complete    1.2s
   ✔ 724ddb9b523f Pull complete    2.8s
   ✔ 32581b0068b9 Pull complete    1.7s
   ✔ 4f4fb700ef54 Pull complete    2.0s
[+] Running 4/4
 ✔ Container hosting-wanderer_db-1         Running    0.0s
 ✔ Container hosting-wanderer-1            Started    1.2s
 ✔ Container caddy-gen                      Running    0.0s
$ docker images --filter=reference='wandererltd/community-edition:*'
REPOSITORY                            TAG           IMAGE ID       CREATED        SIZE
wandererltd/community-edition   v2.1          63f7c8708294   6 days ago     83.4MB
wandererltd/community-edition   v2.1.0-rc.0   2b2735265a65   7 months ago   163MB
$ docker rmi 2b2735265a65
Untagged: wandererltd/community-edition:v2.1.0-rc.0
...
```

> [!TIP]
> You can omit <kbd>-f docker-compose.yml -f reverse-proxy/docker-compose.caddy-gen.yml</kbd> if you are not using Caddy.

Changes in major versions would involve performing a data migration (e.g. [v2.0.0](https://github.com/wanderer-industries/wanderer/releases)) or some other extra step.

## Configure

Wanderer is configured with environment variables, by default supplied via [wanderer-conf.env](./wanderer-conf.env) [env_file.](./docker-compose.yml#L38-L39)

> [!WARNING]
> Note that if you start a container with one set of ENV vars and then update the ENV vars and restart the container, they won't take effect due to the immutable nature of the containers. The container needs to be **recreated.**

#### Example configurations

Here's the minimal configuration file we got from the [quick start:](#quick-start)

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
WEB_APP_URL=https://wanderer.example.com
SECRET_KEY_BASE=GLVzDZW18FzuS2gMcmBRVhwgd4Gu7YmSl/k/TqfTUXti7FLBd7aflXeQDdwCj6Cz
CLOAK_KEY=dsxvbn5jxDd16az2QpsX5B8O+llxjQ6SJE2i5Bzx56I=
EVE_CLIENT_ID=dsxvbn4jxDd11az2QpsX5B8O+llxjQ6SJE2i1Bzx56I=
EVE_CLIENT_SECRET=GLVzqfTUXti7FLBd7aflXeQDdwCj6Cz
```

And here's a configuration with some extra options provided:

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
WEB_APP_URL=https://wanderer.example.com
SECRET_KEY_BASE=GLVzDZW18FzuS2gMcmBRVhwgd4Gu7YmSl/k/TqfTUXti7FLBd7aflXeQDdwCj6Cz
CLOAK_KEY=dsxvbn5jxDd16az2QpsX5B8O+llxjQ6SJE2i5Bzx56I=
EVE_CLIENT_ID=dsxvbn4jxDd11az2QpsX5B8O+llxjQ6SJE2i1Bzx56I=
EVE_CLIENT_SECRET=GLVzqfTUXti7FLBd7aflXeQDdwCj6Cz
WANDERER_INVITES=true
```

Here're the currently supported ENV vars:

### Required

#### WEB_APP_URL

Configures the base URL to use in link generation, doesn't have any defaults and needs to be provided in the ENV vars

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
WEB_APP_URL=https://wanderer.example.com
```

> [!NOTE]
> In production systems, this should be your ingress host (CDN or proxy).

---

#### SECRET_KEY_BASE

Configures the secret used for sessions in the dashboard, doesn't have any defaults and needs to be provided in the ENV vars, can be generated with OpenSSL:

<sub><kbd>console</kbd></sub>
```console
$ openssl rand -base64 48
GLVzDZW18FzuS2gMcmBRVhwgd4Gu7YmSl/k/TqfTUXti7FLBd7aflXeQDdwCj6Cz
```

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
SECRET_KEY_BASE=GLVzDZW04FzuS1gMcmBRVhwgd4Gu9YmSl/k/TqfTUXti7FLBd7aflXeQDdwCj6Cz
```

> [!WARNING]
> Don't use this exact value or someone would be able to sign a cookie with `user_id=1` and log in as the admin!

---

#### CLOAK_KEY

Configures the secret used for encrypting User characters sensitive data at rest using AES256-GCM, doesn't have any defaults and needs to be provided in the ENV vars, can be generated with OpenSSL:

<sub><kbd>console</kbd></sub>
```console
$ openssl rand -base64 32
dsxvbn5jxDd16az2QpsX5B8O+llxjQ6SJE2i5Bzx56I=
```

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
CLOAK_KEY=dsxvbn5jxDd16az2QpsX5B8O+llxjQ6SJE2i5Bzx56I=
``````

### Registration

#### WANDERER_INVITES

Default: `false`

Restricts registration of new users. Possible values are `true` (access by invite only), `false` (no restriction).

---

#### PORT

Default: `8000`

Configures the port to bind the listen socket for the web server.

---

### Database

Wanderer uses PostgreSQL for storing user data. Use the following variables to configure them.

---

#### DATABASE_UNIX_SOCKET

Default: not set

Configures to use a Unix socket for connecting to PostgreSQL database.

Example value: `/var/run/postgresql`

> [!NOTE]
> If you set DATABASE_UNIX_SOCKET, DATABASE_URL should be set to  database name (eg. `wanderer_db`).


---

#### DATABASE_URL

Default: `postgres://postgres:postgres@wanderer_db:5432/wanderer_db`

Configures the URL for PostgreSQL database.

> [!NOTE]
> If you set DATABASE_UNIX_SOCKET, DATABASE_URL should be set to  database name (eg. `wanderer_db`).

---

#### ECTO_IPV6

Enables Ecto to use IPv6 when connecting to the PostgreSQL database. Not set by default.

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
ECTO_IPV6=true
```

---

#### CUSTOM_ROUTE_BASE_URL

URL to running custom routes service (https://github.com/DanSylvest/eve-route-builder).

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
CUSTOM_ROUTE_BASE_URL=http://localhost:2001
```

**Note:** You can run the custom routes service locally with `docker run -p 2001:2001 dansylvest/eve-route-builder:latest`
By default it's configured to run along with Wanderer using docker-compose.

---

### Administration

Wanderer provides an Admin panel for managing the Wanderer instance. Use the following variables to configure it.

---

#### WANDERER_ADMIN_USERNAME

Default: *admin*

Configures the Admin username required to access the Admin panel.

---

#### WANDERER_ADMIN_PASSWORD

Default: *not set*

Configures the Admin password required to access the Admin panel (and Errors page) (using basic auth).

**Note:** If not set, the Admin panel (and Errors page) will be accessible without authentication.

---

#### WANDERER_MAP_SUBSCRIPTION_CHARACTERS_LIMIT

Default: 10000

Configures the limit of active tracking characters per map.

---

#### WANDERER_MAP_SUBSCRIPTION_HUBS_LIMIT

Default: 100

Configures the limit of hubs can be used to calc routes.

---

#### WANDERER_RESTRICT_MAPS_CREATION

Default: false

Restricts creation of new maps. Possible values are `true` (allow creation only by server admins, from the Admin panel), `false` (allow creation by any registered users).

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
WANDERER_RESTRICT_MAPS_CREATION="true"
```

---

#### WANDERER_MAP_CONNECTION_AUTO_EXPIRE_HOURS

Default: 24

Configures the timeout for map connections auto-expire.

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
WANDERER_MAP_CONNECTION_AUTO_EXPIRE_HOURS=24
```

---

#### WANDERER_MAP_CONNECTION_AUTO_EOL_HOURS

Default: 21

Configures the timeout for map connections auto-EOL.

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
WANDERER_MAP_CONNECTION_AUTO_EOL_HOURS=21
```

---

#### WANDERER_MAP_CONNECTION_EOL_EXPIRE_TIMEOUT_MINS

Default: 60

Configures the timeout for expired map connections auto-removal.

<sub><kbd>wanderer-conf.env</kbd></sub>
```env
WANDERER_MAP_CONNECTION_EOL_EXPIRE_TIMEOUT_MINS=60
```

---

## FAQ

<details>
<summary>How do I access Wanderer from terminal?</summary>

You can start an Interactive Elixir session from within the `wanderer` container:

<sub><kbd>console</kbd></sub>
```console
$ cd hosting # or wherever you cloned this repo
$ docker compose exec wanderer bin/wanderer_app remote
```
```elixir
iex> Application.get_all_env :wanderer_app
[
  {WandererAppWeb.Endpoint,
   [
     live_view: [signing_salt: "f+bZg/crMtgjZJJY7X2OwIWc3XJR3C8Y"],
     pubsub_server: WandererApp.PubSub,
     render_errors: [
       view: WandererAppWeb.ErrorView,
       layout: {WandererAppWeb.LayoutView, "base_error.html"},
       accepts: ["html", "json"]
     ]
# etc.
# use ^C^C (ctrl+ctrl) to exit
```

</details>

<details>
<summary>How do I access PostgreSQL from terminal?</summary>

You can start a `psql` session from within the `wanderer_db` container:

<sub><kbd>console</kbd></sub>
```console
$ cd hosting # or wherever you cloned this repo
$ docker compose exec wanderer_db psql -U postgres -h localhost -d wanderer_db
```
```sql
wanderer_db=# \d

--  Schema |                      Name                      |   Type   |  Owner
-- --------+------------------------------------------------+----------+----------
--  public | users                                          | table    | postgres
--  public | users_id_seq                                   | sequence | postgres

wanderer_db=# exit
```

</details>
