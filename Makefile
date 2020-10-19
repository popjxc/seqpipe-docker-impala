all: seqpipe-docker-impala.flag

seqpipe-docker-impala.flag:
	docker build . -t seqpipe/seqpipe-docker-impala:latest && touch seqpipe-docker-impala.flag

publish: seqpipe-docker-impala.flag
	docker push seqpipe/seqpipe-docker-impala:latest

clean:
	rm -f seqpipe-docker-impala.flag
