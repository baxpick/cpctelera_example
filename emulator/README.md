## Instructions

1.  **Prepare**
    ```bash
    cd emulator
    cp /path/to/your/game.dsk ./cpc
    ```
2.  **Host emulator files**
    ```bash
    docker run --rm -it -p 8080:80 -v "$(pwd)":/usr/share/nginx/html nginx:alpine
    ```

3.  **Access the emulator (Amstrad CPC)**

    Open your web browser and go to:

    http://localhost:8080/cpc/cpc.html?file=game.dsk

    Type: (something like this)

    ```
    CAT
    RUN "PCLIMBER"
    ```

    or if you already know what to run inside dsk image, go to something like:

    http://localhost:8080/cpc/cpc.html?file=game.dsk&input=run%22PCLIMBER%0A

4.  **Stop the server:**

    Control-C
