# AEGEE-Europe's Online Membership System
## `MyAEGEE`

## Description
The repository for the ["Online Membership System" (OMS)](https://github.com/AEGEE/MyAEGEE), an open-source project of the student/youth association [AEGEE-Europe](http://aegee.org/).

It makes use of docker, and docker-compose.

[Read more about the project](https://myaegee.atlassian.net/wiki/spaces/GENERAL/overview)

# Installation

Explanation of the installation are here. Explanation of why we're doing it this way is [at the bottom](#Under-the-hood).

A note on terminology:
- The computer you run Virtualbox on is the _HOST_.
- The created VM which runs Docker is the _GUEST_.

## Pre-requisites: installations required

Install [Virtualbox](https://www.virtualbox.org/wiki/Downloads) first, then [Vagrant](https://www.vagrantup.com/downloads.html). Even if you have a linux box, this is **very** recommended.
If you decide to not do it, *sigh...* but don't come to cry to us.

If you decide you know better than us, [install docker and docker-compose](https://docs.docker.com/compose/install/) on your Windows/Linux/Mac machine, instead of Virtualbox and Vagrant. (Make sure you install the correct versions: tested with Docker CE 19.03.1 and docker-compose 1.24.1)

Note: if you use Vagrant, Docker will be already automatically on the virtual machine.

Memory requirements for the VM bootstrapped with Vagrant: 2GB (i.e. you need a machine with at least 3GB physical RAM)

## Pre-requisites: URL mapping

To be able to use advanced features, you are encouraged to edit (a script will do it for you, read below) the `/etc/hosts` file on the _HOST_ machine (on windows: `C:\Windows\system32\drivers\etc\hosts`) to add the entry:

Vagrant case: `192.168.168.168 appserver.test my.appserver.test traefik.appserver.test portainer.appserver.test pgadmin.appserver.test`

Pure docker case: `127.0.0.1 appserver.test my.appserver.test traefik.appserver.test portainer.appserver.test pgadmin.appserver.test`

In the linux case, it is handled by `start.sh`. More on the launching of this script later.
As a helper in the windows case, you have the script "`run_as_win_administrator.bat`" (not very advanced). You have to right-click it and click "run as administrator". It will tell you the line to copy (on another terminal that will open) and open the file you need to edit in notepad. Paste the content at the last line of the file, save, and exit.

Now you can install the system!

### Install the web application (linux):

> On the _HOST_
```
git clone --recursive https://github.com/AEGEE/MyAEGEE.git
cd MyAEGEE
./start.sh
```

You will have to wait for up to 20'. A message appears when the bootstrap completes, and you can check if it works in the ways described in the [usage section](#accessing-it).

See [below](#start.sh-and-Makefile) for explanation of `start.sh`

### Install the web application (non-linux):

> On the _HOST_
```
git clone --recursive https://github.com/AEGEE/MyAEGEE.git
cd MyAEGEE
vagrant up
```

You will have to wait for up to 20'. A message appears when the bootstrap completes, and you can check if it works in the ways described in the [usage section](#accessing-it).

## Configuration file
Everything related to the behaviour of the app is defined in the top-most `.env` file. Most important parameters are:

`ENABLED_SERVICES`: telling which parts of the system are enabled

`MYAEGEE_ENV`: telling in which mode the system is run

`<servicename>_SUBDOMAIN`: telling how to access a specific service

See [below](#moving-parts) for more info.

# Usage

## Accessing it

After launching the system, you have two ways to check everything is working:

1) on the _HOST_
```
# on the _HOST_ you run the following

vagrant ssh

# ...which connects you to the _GUEST_, where docker is.
# So now you can run:

docker ps
```

Let's run the commands and see that they should yield an output like
```
username@computername:~/Documents/aegee/MyAEGEE$ vagrant ssh
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-111-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

 System information disabled due to load higher than 1.0

 * Kubernetes 1.19 is out! Get it in one command with:

     sudo snap install microk8s --channel=1.19 --classic

   https://microk8s.io/ has docs and details.

97 packages can be updated.
70 updates are security updates.


This system is built by the Bento project by Chef Software
More information can be found at https://github.com/chef/bento
Last login: Fri Sep 18 14:13:43 2020 from 10.0.2.2

appserver[/vagrant]$ [master !?]
```
```
appserver[/vagrant]$ [master !?] docker ps
CONTAINER ID        IMAGE                                  COMMAND                  CREATED             STATUS                 PORTS                                      NAMES
cbe689ea9ee2        aegee/discounts:dev                    "docker-entrypoint.s…"   5 hours ago         Up 5 hours (healthy)   8084/tcp                                   myaegee_discounts_1
ed1c20a4e65a        aegee/statutory:dev                    "docker-entrypoint.s…"   5 hours ago         Up 5 hours (healthy)   8084/tcp                                   myaegee_statutory_1
f60476fa4a6c        aegee/events:dev                       "docker-entrypoint.s…"   5 hours ago         Up 5 hours (healthy)   8084/tcp                                   myaegee_events_1
06add303acd0        aegee/core:dev                         "docker-entrypoint.s…"   5 hours ago         Up 5 hours (healthy)   8084/tcp                                   myaegee_core_1
72a7cb2d4100        postgres:10                            "docker-entrypoint.s…"   5 hours ago         Up 5 hours             5432/tcp                                   myaegee_postgres-statutory_1
316ced849d6f        postgres:10                            "docker-entrypoint.s…"   5 hours ago         Up 5 hours             5432/tcp                                   myaegee_postgres-core_1
f3110b11d9c6        postgres:10                            "docker-entrypoint.s…"   5 hours ago         Up 5 hours             5432/tcp                                   myaegee_postgres-discounts_1
9985f6cd3042        postgres:10                            "docker-entrypoint.s…"   5 hours ago         Up 5 hours             5432/tcp                                   myaegee_postgres-events_1
623356e7ef0d        dpage/pgadmin4:4.23                    "/entrypoint.sh"         6 hours ago         Up 6 hours             80/tcp, 443/tcp, 5050/tcp                  myaegee_pgadmin_1
0728da470558        erikdubbelboer/phpredisadmin:v1.11.4   "tini -- php -S 0.0.…"   6 hours ago         Up 6 hours             80/tcp                                     myaegee_redisadmin_1
8263f843df15        portainer/portainer:1.22.1             "/portainer -H unix:…"   6 hours ago         Up 6 hours             9000/tcp                                   myaegee_portainer_1
d056ce2c92e3        swaggerapi/swagger-ui:v3.28.0          "/docker-entrypoint.…"   6 hours ago         Up 6 hours             80/tcp, 8080/tcp                           myaegee_swagger_1
4ee964dede44        traefik:v1.7.4-alpine                  "/entrypoint.sh --we…"   6 hours ago         Up 6 hours (healthy)   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   myaegee_traefik_1
30963e2faf63        aegee/portal:dev                       "docker-php-entrypoi…"   6 hours ago         Up 6 hours             80/tcp                                     myaegee_portal_1
49485e19dc87        aegee/frontend:dev                     "nginx"                  6 hours ago         Up 6 hours             80/tcp, 8083/tcp                           myaegee_frontend_1
e81bcc38bf76        aegee/nginx-static:latest              "nginx -g 'daemon of…"   6 hours ago         Up 6 hours (healthy)   80/tcp                                     myaegee_statutory-static_1
dc2ea7b33c97        aegee/nginx-static:latest              "nginx -g 'daemon of…"   6 hours ago         Up 6 hours (healthy)   80/tcp                                     myaegee_events-static_1
```

what do we see here? That we can connect to vagrant (we are inside the virtual machine with `vagrant ssh`), and that a bunch of containers are up (we ask the docker containers with `docker ps`). We'll see later that we should use some commands (`make start`) on the _GUEST_, so knowing how to access the virtual machine is important.

**HOORAY! YOUR SYSTEM IS UP!**

2) you can navigate to it in your _HOST_ web browser.

For accessing it, the three most important URLs (*NB there is no https for development*):

| Service | URL | Description |
|---|---|---|
| The app (MyAEGEE) | http://my.appserver.test | What you're here for |
| Traefik | http://traefik.appserver.test | Quick test to see if everything works well |
| Portainer | http://portainer.appserver.test | Visual docker manager |

Do you connect to any of these three URLs without troubles? **HOORAY! YOUR SYSTEM IS UP!**

See right below for the URL of extra services.

See at the bottom for the [default credentials](#default-credentials) of MyAEGEE's fresh install.

### Subdomains registered on traefik
read "_subdomain_.appserver.test"; e.g. you put in your _HOST_ browser `http://traefik.appserver.test`

|Subdomain|What|Container|
|---|---|---|
| my | MyAEGEE | frontend |
| portainer | Easier container mgmt (development only) (under login)  | portainer |
| traefik | Traefik's dashboard (under login) | traefik |
| pgadmin | Administration of databases (development only) (under login) | pgadmin |
| www | Website | wordpress |
| wiki | AEGEE's Wiki, the backbone of knowledge | mediawiki |

You can customise these subdomains by editing the `.env` file as mentioned above, and relaunching the script (see below about `Makefile`).


FIXME: [For more detailed usage guides see this usage tips page.](https://myaegee.atlassian.net/wiki/spaces/GENERAL/pages/23655986/Usage+tips)
For container-specific usage guides see the container's repository.

## Easy script to manipulate the installation

(At the end of this section there will be links to detailed explanations, don't panic!)

There is a file called `Makefile` that gives some easy shortcut to do stuff. This must be launched on the _GUEST_.

On first run of vagrant, the `bootstrap` target will be invoked (you don't need to do it). If you are stubborn and decide to not use Vagrant, you still don't have to invoke it (it is invoked by `start.sh`)

The general flow is that once you edit the `.env` file, `make start` should be run (on the _GUEST_) to update the running configuration.

You can invoke the easy scripting in the following way (this shell command must be run in the same folder of the `Makefile`):

> On the _GUEST_

| Command | What |
|---|---|
| make bootstrap | (`init`, `build`, `start`) in this order. (Run only the first time by vagrant/`start.sh`) |
| make init | Initialise the system (most likely you don't need to launch this) |
| make build | Build the containers registered in the .env file |
| make start | Run the containers registered in the .env file |
| make monitor | If you didn't enable kibana, then you may want to have a look at the logs through this |
| make live-refresh | Updates the containers to the new version (if any) and restarts them |
| make stop/restart/hard-restart | Just don't use them on the server, EVER |
| make bump | Only for development: updates the submodules |

Guest? Host? wtf? read the [under the hood](#under-the-hood) section, and the [difference between start.sh and makefile](#start.sh-and-Makefile).

### Reading the logs

For now, if one wants to follow some specific logs, they have to invoke helper.sh manually e.g.
```
./helper.sh --monitor container1 container2...containerN
```

Likewise, for now if one wants to execute a command on a container they have to invoke helper.sh manually e.g.
```
./helper.sh --execute containername command
```

## What's next?

It's your time to shine! Your system is set up, now it's up to you to create a new service, to improve an existing one, or to play with integrations leveraging existing services (e.g. wordpress, magento...). See the [moving parts](moving-parts) section that explain how to configure the system after you add something new.

For better development experience: the files in your _HOST_ folder `MyAEGEE` are mounted inside the _GUEST_ (location `/vagrant`), which means that if you create a file in the _GUEST_ `/vagrant` folder you will find it in your _HOST_ `<your cloned dir>/MyAEGEE`, and vice versa if you edit a file in your repository it is reflected in the VM. This way you can use the IDE you use normally on the system you use normally, without the need of getting accustomed to some new tool!

Make sure however to use an extension in your IDE called [editorconfig](https://editorconfig.org/#download)! It will avoid pains especially if your _HOST_ is a windows machine.

### Configure git and GitHub on your computer
- setup an SSH key to talk to GitHub [documentation](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account). It is possible to use HTTPS if you prefer or if SSH is blocked for you. SSH access allows you never to have to enter your password on pull and push operations
- edit your local configuration:
    - a global gitignore adapted to your OS, so that temp files don't get committed. Have a look at [how to setup the .gitignore file](https://docs.github.com/en/free-pro-team@latest/github/using-git/ignoring-files) as well as [the rules to put in that file](https://github.com/github/gitignore)
    - configure a name and email address you're willing to disclose in the history. GitHub offers you the possibility to use an anonymous address. [This article](https://docs.github.com/en/free-pro-team@latest/github/setting-up-and-managing-your-github-user-account/setting-your-commit-email-address) explains both possibilities.


### Local repositories' organization on the filesystem

The `MyAEGEE` repository contains several git submodules. Submodules are roughly pointers to specific versions of other git repositories. You will most probably **not** commit to the current repository, but you will rather make edits on the frontend, events, or discounts repositories.

```bash
# steps from the readme
git clone --recursive git@github.com:AEGEE/MyAEGEE.git
cd MyAEGEE
# do a second clone of the repos that are of interest
mkdir myRepoClones
cd myRepoClones
git clone git@github.com:AEGEE/core.git
git clone git@github.com:AEGEE/events.git
git clone git@github.com:AEGEE/frontend.git
git clone git@github.com:AEGEE/statutory.git
# so that git does not complain about changes when using git from the "MyAegee" folder.
echo "**" > .gitignore
```

The folder structure you should have after running the steps above looks like this (the output below was trimmed a bit)
```
user@computer:~/Documents/aegee/MyAEGEE$ tree -L 2 -a
.
├── base-docker-compose.yml
├── .circleci
│   └── config.yml
├── core
│   ├── CHANGELOG.md
│   └── .yamllint.yml
├── .env
├── .env.example
├── events
│   ├── apiary.apib
│   └── .yamllint.yml
├── helper.sh
├── Makefile
├── monitor
│   └── docker
├── myRepoClones
│   ├── core
│   ├── discounts
│   ├── events
│   ├── frontend
│   ├── .gitignore
│   └── statutory
├── oms-global
(...)
```

Edit the `.env` file and add the second section below the "Paths in the filesystem"
```yaml
# Paths in the filesystem
PATH_GATEWAYS=gateways/docker/
PATH_CORE=core/docker/
PATH_EVENTS=events/docker/
PATH_STATUTORY=statutory/docker
PATH_FRONTEND=frontend/docker/
PATH_DISCOUNTS=discounts/docker/
PATH_MAILER=mailer/docker/
PATH_PASS_MANAGER=pass-manager/docker/
PATH_MONITOR=monitor/docker/
PATH_GSUITE_WRAPPER=gsuite-wrapper/docker/
PATH_OMS_ELASTIC=oms-elastic/docker/

# My private repos, overriding the default paths
PATH_EVENTS=myRepoClones/events/docker/
PATH_FRONTEND=myRepoClones/frontend/docker/
#PATH_STATUTORY=myRepoClones/statutory/docker
```

With this setup, you can easily override the code running in production (= the code in the submodules) with the one you have locally (the repos in `myRepoClones`). Having duplicated keys in a `.env` will be displayed as a warning in your IDE, so you will notice through IDE warnings when you are overriding repositories and when you are using the version in production. In the example above, I'm using my own version of events and frontend, but the prod version of statutory.

After a change to the `.env` file, you need to run `make start` on the _GUEST_.

### Update the local repositories

Changes happen on all the repositories, and while breaking changes are the exception rather than the norm, it is good practise to update all your repositories every once in a while, especially the `MyAEGEE` one, since it's the one running in production.

1. To update your copies of the submodules
```
  user@computer:~/Documents/aegee/MyAEGEE$ cd myRepoClones/discounts/
  user@computer:~/Documents/aegee/MyAEGEE/myRepoClones/discounts$ git checkout master
Already on 'master'
Your branch is up to date with 'origin/master'.
  user@computer:~/Documents/aegee/MyAEGEE/myRepoClones/discounts$ git pullremote: Enumerating objects: 63, done.
remote: Counting objects: 100% (63/63), done.
remote: Compressing objects: 100% (62/62), done.
remote: Total 63 (delta 35), reused 15 (delta 1), pack-reused 0
Unpacking objects: 100% (63/63), done.
From github.com:AEGEE/discounts
   5dcfa5d..0d8bdfa  master     -> origin/master
 * [new branch]      dependabot/npm_and_yarn/eslint-plugin-react-7.21.2 -> origin/dependabot/npm_and_yarn/eslint-plugin-react-7.21.2
Updating 5dcfa5d..0d8bdfa
Fast-forward
 config/index.js                          |    1 -
 lib/bugsnag.js                           |    4 +-
 lib/middlewares.js                       |    4 +-
 lib/server.js                            |    4 +-
 models/Category.js                       |    2 +-
 package-lock.json                        | 1910 +++++++++++++++---------------
 package.json                             |   20 +-
 test/api/codes-claiming.test.js          |    1 -
 test/api/integrations-population.test.js |    1 -
 test/api/metrics.test.js                 |    1 -
 test/scripts/mock.js                     |    1 -
 11 files changed, 969 insertions(+), 980 deletions(-)
  user@computer:~/Documents/aegee/MyAEGEE/myRepoClones/discounts$

# next step: merge master in your local branch, or rebase your local branches on top on this fresh master
```

2. To update the MyAEGEE repository
We need to update the repository as well as all of its submodules with the `git pull --recurse-submodules` command, which will give an output similar to this.
```
user@computer:~/Documents/aegee/MyAEGEE$ git pull --recurse-submodules
remote: Enumerating objects: 3, done.
remote: Counting objects: 100% (3/3), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 3 (delta 0), reused 3 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), done.
From https://github.com/AEGEE/MyAEGEE
 * [new branch]      make_add_discounts -> origin/make_add_discounts
Fetching submodule core
From https://github.com/AEGEE/core
 * [new branch]      dependabot/npm_and_yarn/eslint-plugin-mocha-8.0.0 -> origin/dependabot/npm_and_yarn/eslint-plugin-mocha-8.0.0
 * [new branch]      dependabot/npm_and_yarn/eslint-plugin-react-7.21.2 -> origin/dependabot/npm_and_yarn/eslint-plugin-react-7.21.2
   d7a8e54..ebd284b  master     -> origin/master
 * [new tag]         1.26.0     -> 1.26.0
Fetching submodule discounts
Fetching submodule events
From https://github.com/AEGEE/events
   2548876..f5ab1ad  master     -> origin/master
Fetching submodule gateways/docker/portal/files
Fetching submodule mailer
Fetching submodule statutory
From https://github.com/AEGEE/statutory
Already up to date.

```
If you want to test the website with all the latest versions, remember to disable your own copies of the sub repositories and redeploy, as described in section [Local repositories' organization on the filesystem](#local-repositories-organization-on-the-filesystem)

### Feature development: submit your first pull request

Discuss with us on Jira about taking a task, and get it assigned to yourself. It will have an identifier like "MA-999" or "HELP-425". For the following example, let's assume we need to work on MA-999, which fixes a bug on statutory.

Set the status of the bug to "IN PROGRESS" once you start working on it. The example below shows the usual git workflow: create a branch, edit a few files, commit those files, and open a Pull Request (PR) on GitHub for others to review.

```txt
user@computer:~/Documents/aegee/MyAEGEE$ cd myRepoClones/statutory/

# create a new branch in our copied repo, not in the submodule one
user@computer:~/Documents/aegee/MyAEGEE/myRepoClones/statutory$ git checkout -b MA-999/new_feature_cool_stuff

# (edit some files in order to fix the bug...)

# git commit: the linting will execute: make sure that your commit messages respects the naming rules
$ git add -uv
$ git commit
$ git push -u origin MA-999/new_feature_cool_stuff

Go to Github, and create a PR in the AEGEE/statutory repo.
```
After your push, go to Jira, and set the status of the bug to "AWAITING REVIEW".

### Development tools

#### IDE

We recommend using an IDE for development. This will speed up your work by a lot. There are many options out there:
- [Visual Studio Code](https://code.visualstudio.com/)
- [WebStorm](https://www.jetbrains.com/webstorm/nextversion/): use EAP versions or a student license: both options are fine because the project is open-source and non-commercial.

#### PgAdmin: tool to inspect the PostgreSQL database

This tool is useful to see the state of the database: its schemas, and also the content.

It is already installed for you in the _GUEST_ machine, and available on [http://pgadmin.appserver.test/browser/](http://pgadmin.appserver.test/browser/#) (in the _HOST_ browser)
We have several database containers = several database servers. They all use the `postgres:10` image (visible on [http://portainer.appserver.test/#/containers](http://portainer.appserver.test/#/containers))
- myaegee_postgres-statutory_1
- myaegee_postgres-core_1
- myaegee_postgres-discounts_1
- myaegee_postgres-events_1

In the pgadmin UI, you must thus create four servers to read all the data.

In the main UI, right-click on Servers (0), and click `Create -> Server`. Give it a name (example: statutory): this name is only for you to read in the UI.
Click on the `Connection` tab:
- hostname/address: `postgres-statutory`. This value comes from the `current-config.yml` file. (another way is to take the container name, and remove the leading `myaegee_` and trailing `_1`)
- username: `postgres`
- password: `5ecr3t`

The values to write can be found in the `current-config.yml` file.
```yaml
 postgres-statutory:
    environment:
      POSTGRES_PASSWORD: 5ecr3t
      POSTGRES_USER: postgres
    expose:
    - '5432'
    image: postgres:10
    restart: always
    volumes:
    - postgres-statutory:/var/lib/postgresql/data:rw
```

After confirming the connection to the server, you will find the tables in `statutory (the name you gave) -> Databases -> statutory -> Schemas -> public -> Tables`.

You may check the pgadmin documentation on [using the query tool](https://www.pgadmin.org/docs/pgadmin4/latest/query_tool.html) and on [viewing and editing data](https://www.pgadmin.org/docs/pgadmin4/latest/editgrid.html).

## Contribute
[You can read more about contributing on our confluence.](https://myaegee.atlassian.net/wiki/spaces/GENERAL/overview)

## Issue tracker
[We use JIRA as our preferred issue tracker.](https://myaegee.atlassian.net/projects/MEMB/issues)

## Licence
Apache License 2.0, see LICENSE.txt for more information.

# Under the hood

`Virtualbox` is a utility that lets people creating virtual machines (VM) on your computer. The created VM is the _GUEST_. The computer you run Virtualbox on is the _HOST_

`Vagrant` is used as a tool to define VMs characteristics, that will be then run through Virtualbox - in other words, it is used so we can write a manifesto that defines the characteristics of a VM, and the VM generated has always the same characteristics. It is useful in this case to model the development VM just as if it was the server on which we will run the application.

`Make` is a tool that, among other things, chains commands together. So, for instance, you write in the `Makefile` that `a` runs a specific long command, `b` a different long command, and you can call the commands with `make a` or `make b`. You can also write a command `c` which is a chain of `a` followed by `b`. We use it to set a 'flow' of operations that should be followed (e.g. as explained, `make bootstrap` chains 3 operations, and one such operation is used very often i.e. `build` and/or `start`). This is used on the _GUEST_.

`start.sh` runs either `vagrant up` or `make bootstrap` (according to how you want to run your system in local) so one has to literally only launch one command and it's set to be working, after the startup time of around 10-20 minutes (according to internet connection speed). This is used on the _HOST_.

### `start.sh` and Makefile

> `start.sh`

On the _HOST_, i.e. the machine that runs the virtual machine, you use `start.sh` which can either:
- Start the vm
  - Use `./start.sh` for normal development cycle: app runs in development mode
  - Use `./start.sh --fast` for sysops/integration development cycle: app runs in production mode so you can concentrate on developing integration to the app, not the app itself
- Reset the settings to recreate the virtual machine (`./start.sh --reset`). This is in case you experimented so hard that you made something exploooode. Doing so, you will lose the users and other content you created on your local instance of MyAEGEE, but this will not remove your source code.

If you are a know-it-all who doesn't want to use Vagrant, use `./start.sh --no-vagrant` (but again, if you're in trouble you will only get superficial support from our side)

> Makefile

On the _GUEST_, i.e. the virtual machine that runs docker, you use `make` which uses the `Makefile` (explained [above](#easy-script-to-manipulate-the-installation)).

## Individual containers

For prerequisites and installation of individual containers, see their `docker`(/`-compose`) files, located in the `(service)/docker` folder in their respective repository.

For more detailed info, we hoped to have a better knowledge base [here](https://myaegee.atlassian.net/wiki/spaces/GENERAL/pages/224231425/Microservices+information), it's not great right now but it's a something `¯\_(ツ)_/¯`

## Moving parts

### .env
The file contains variables where e.g. you define the base url (`aegee.test`) and where will various app be reachable (e.g. `my.` for `my.aegee.test` to reach the frontend).

List of defined variables:
- base url
- subdomain urls
- activated services
- runtime environment
- some default passwords
- SMTP user/pass/server for mailer
- Sendgrid user/pass
- Superadmin credentials (for other services to read; it does not set them in the system)
- folder locations

so for instance...

*Example 1*: you would use this file if you had a problem with 1 microservice and wanted to remove it from the setup. Note: the removal of the ms would not stop a container if there was one running already, so make sure you cleanup (not mandatory, just avoids headaches in case of troubleshooting and "oh, I forgot about this).
How would you do that? Example: discounts
- Edit .env file
- Remove the service from the array `ENABLED_SERVICES`
- `docker stop myaegee_discounts_1 && docker rm myaegee_discounts_1` (on the _GUEST_)

*Example 2*: you would use this file if you wrote a new microservice and wanted to add it from the setup.
How would you do that? Example: your service is into a folder called `boombastic` (at the same level of the folders `core`,`events` etc)
- Edit .env file
- Add the service at the end of the array `ENABLED_SERVICES=<whatever is here already>:boombastic`. Remember: all the services are separated by colon (`:`)
- `make start` (on the GUEST)

### docker-compose.yml
In the docker-compose files there are the definitions of where an app should be reached.

Docker-compose will use the variables defined above, and put them under the `labels` section of a container (if a container needs it). The `labels` section is parsed by traefik to route all the HTTP calls to the correct containers. In other words, this is where the values contained in the `.env` file are used to specify that the app replies on '`my.`appserver.test' instead of e.g. '`magic.`appserver.test'.

### /etc/hosts

This file which is located on the _HOST_ machine is used to add new [subdomains for the services](#subdomains-registered-on-traefik): e.g. add `pgadmin` to be able to go to `pgadmin.appserver.test` and use a visual tool for the databases. The important part is that this name of subdomain matches the one defined in the file `.env`

# Troubleshooting / other

- Remember to check what is running on your _GUEST_ via `docker ps` (or portainer). Enter your _GUEST_ with `vagrant ssh` (from your _HOST_).

- If you are stuck and something doesn't seem to work, make sure you don't have a mismatch between `/etc/hosts`, the URL you type in the browser, and the address that the system expects. See file `current-config.yml` for that: it is a file which is generated every time `make start` is launched. It contains the description of the desired state of the app. NB: `/etc/hosts` is the only file mentioned in this README that only exists in the _HOST_ and is not mounted (as described above).

- You can add dev-tools to the array of services and troubleshoot docker using portainer (mentioned above). Make sure that you have added also the URL to the hostfile (`/etc/hosts`) and that it matches the variable defined in `.env`

- As written in the 'moving parts' section: if you remove services from array `ENABLED_SERVICES`, they are not stopped. This is not a problem in general, just don't be surprised if when you start (having the configuration `ENABLED_SERVICES=core:frontend:events`) and stop later (with the configuration `ENABLED_SERVICES=events`) docker writes a message `WARNING: found orphan containers`.

- `make start` calls a script `helper.sh` that will look into all folders described in `ENABLED_SERVICES` for a `docker-compose.yml` file. Then it creates in-memory a giant docker-compose configuration which is what will be run. This configuration is also outputted to a file (`current-config.yml`) for ease of troubleshoot.

- Running the system in `development` mode means that every `docker-compose.yml` has extra-settings in a `docker-compose.dev.yml` file (in the same folder). Some modules are not thought for development mode, if you find an error about a missing `docker-compose.dev.yml` just create an empty one where the system wants it.

## How to run unit/integration tests when you start the system

?? @serge1peshcoff

## Default credentials

From the [core readme](./core/README.md): there are test users. All users have `5ecr3t5ecr3t` as password.

- `admin@example.com` - admin
- `board@example.com` - board member of antenna
- `member@example.com` - regular member of antenna
- `not-confirmed@example.com` - member who is not confirmed
- `password-reset@example.com` - member who requested a password reset
- `suspended@example.com` - a suspended member

You can use `5ecr3t` for a password reset token (for a member with email `password-reset@example.com`) and `5ecr3t` for a mail confirmation (for a member with email `not-confirmed@example.com`).

**NOTICE** if you use the `--fast` mode of `start.sh`, then core does NOT provision in production mode, so you will be fast in bootstrapping but without users to play with. This should not be an issue for you if you are interested in only the infrastructure work; if you however need a user, you can register yourself.

## How to reset the database and recreate

A couple of options

1) As mentioned above, you can enable dev-tools for pgadmin. From there you can delete the db
  - Notice unfortunately you have to configure pgadmin when you first login: specify the host, username, password.
    - Username and password of the database is NOT the same username and password of pgadmin. Find everything in the files mentioned in 'moving parts', or `current-config.yml` for ease.
    - You put the name of the service as hostname (docker internally resolves stuff with its internal DNS). In other words, every container is reachable at the host named like its service (e.g. `frontend`, `core`, `postgres-core`, etc). The 'service' is named in the `docker-compose.yml` under the key `services:`. Again: _the title of the container is also the hostname of the container_

2) Use portainer to delete the service and db, then `make start` to fix everything.
  - The service must be deleted/restarted because it runs the migrations and therefore fills the DB with the important data. If you delete only the db, the service will expect the db to be filled with data, causing errors
