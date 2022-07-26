# Introduction

First, make sure you copy the following file and edit its contents:

```bash
cp .env_template .env
vim .env
```

## Local setup

Set redis_host enviroment to `redis`

Once you have the .env setup, run the following script to init docker-compose service:

```bash
make build-local
```

When done, you should have listed:

```bash
Service is on http://localhost:2000/
```

Access the swagger docs in <http://localhost:2000/docs>

## Infrastructure setup

Variables:

* `PROJECT_NAME` Any arbitrary project name.  Use 'echo' if you don't have any preference.
* `AWS_DEFAULT_REGION` Your preferred AWS region
* `AWS_ACCOUNT_ID` Your account ID as you see [here](https://console.aws.amazon.com/billing/home?#/account)
* `KEY_PAIR` Name of Key Pair you'd like to use to setup the infrastructure. Find it [here](https://ap-northeast-1.console.aws.amazon.com/ec2/v2/home#KeyPairs)

Once you have the .env setup, run the following script to initialize VPC, ECR/ECS and App Service.

```bash
make build-infra
```

When done, you should have listed:

```bash
Bastion endpoint:
54.65.206.60
Public endpoint:
http://clust-LoadB-4RPWCBUJAH83-1023823123.ap-southeast-1.elb.amazonaws.com
```

Access the above load balancer and make sure that you have output like this:

```bash
$ curl -i "http://clust-LoadB-4RPWCBUJAH83-1023823123.ap-southeast-1.elb.amazonaws.com"
HTTP/1.1 200 OK
Date: Mon, 18 Jul 2022 03:29:51 GMT
Content-Type: application/json
Content-Length: 49
Connection: keep-alive
server: uvicorn

{"statusCode":200,"body":"{\"message\": \"OK\"}"}%
```

Congrats! You're successfully done create AI service!

For more service detail, go to [my blog](https://haicheviet.com)
