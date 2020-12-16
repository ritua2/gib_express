### Container orchestration for multiple *gateway-in-a-box* wetty instances


**Deprecated instructions, [middle layer](./../middle-layer) includes both the manager node and greyfish storage**


**Installation**  

All setup is automatic after the repository has been initialized. User simply needs to specify the Redis key,
the base URL for the project, and the base key to be used administrative purposes.



```bash
	# Select a redis password
	URL_BASE=example.com REDIS_AUTH=redispassword orchestra_key=orchestra PROJECT=gib GREYFISH_URL=greyfishexample.com GREYFISH_REDIS_KEY=greyfish  docker-compose up -d --build
```


**Note**

A previous version of the current code, written in go is available [here](./gocode). Both are similar as of May 27th, 2019 but the go version will no longer be maintained.
