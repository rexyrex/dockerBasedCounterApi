docker run --name redis-server -v ${PWD}:/data -p 6379:6379 -d redis redis-server --appendonly yes
