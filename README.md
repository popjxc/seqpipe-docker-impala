# Seqpipe Impala Docker container
___
* Create conda environment `impala` to use with Impala Docker container
  and activate it:

    ```bash
    conda env create -n impala -f conda-environment.yml
    conda activate impala
    ```

* Copy `docker-compose.yml.template` to `docker-compose.yml` and edit source
  directory to match an existing directory on the host file system

* Invoke
  
  ```bash
  docker-compose pull
  ```

  to download the `seqpipe-docker-impala` prebuild Docker image from DockerHub

* Alternatively you can run

    ```bash
    docker-compose build
    ```
  to build the docker image.

* If you want to start Docker container run:

    ```bash
    docker-compose up
    ```
  This will run the docker container specified in `docker-compose.yml` file.

* If you want the Docker container run as a deamon, you can run:
  
    ```bash
    docker-compose up -d
    ```

* If the Docker container is run as a deamon you can stop it by using:

    ```bash
    docker-compose down
    ```

* To see all running Docker continers you can use
  
    ```bash
    docker ps
    ```

* To enter into running Docker container environment you can use:

    ```bash
    docker exec -it <container name/ID> /bin/bash
    ```

  where container name or ID could be found using `docker ps` commnand.


* Simple python function to execute SQL queries on localy running Impla Docker container
  
    ```python
    from impala.dbapi import connect

    def run_sql(sql):
        with connect(host='localhost', port=21050) as conn:
            with conn.cursor() as cursor:
                cursor.execute(sql)
                for row in cursor:
                    print(row)
    ```

  For example you can run:
    ```python
    run_sql("""SHOW DATABASES""")
    ```

