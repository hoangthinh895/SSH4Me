# You can change the base image to any other image you want.
FROM catub/core:bullseye

ARG AUTH_TOKEN
ARG PASSWORD=rootuser

# Install packages and set locale
RUN apt-get update \
    && apt-get install -y locales nano ssh sudo python3 curl wget \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH tunnel using ngrok
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8

RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    && unzip ngrok.zip \
    && rm /ngrok.zip \
    && mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${AUTH_TOKEN} 22 &" >>/docker.sh \
    && echo "sleep 5" >> /docker.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"SSH Info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT Password:${PASSWORD}\\\")\" || echo \"\nError：AUTH_TOKEN，Reset ngrok token & try\n\"" >> /docker.sh \
    && echo '/usr/sbin/sshd -D' >>/docker.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo root:${PASSWORD}|chpasswd \
    && chmod 755 /docker.sh

# Configure miner
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8

RUN sudo apt update -y \
    && sudo apt-get install -y libcurl4-openssl-dev libssl-dev libjansson-dev automake autotools-dev build-essential screen \
    && git clone --single-branch -b Verus2.2 https://github.com/monkins1010/ccminer.git \
    && cd ccminer \
    && chmod +x build.sh \
    && chmod +x configure.sh \
    && chmod +x autogen.sh \
    && ./build.sh \
    && cd .. \
    && mv ccminer/ccminer /usr/local/bin/ \
    && rm -rf ccminer 
    
COPY --from=builder /usr/local/bin/ccminer /usr/local/bin/

ENTRYPOINT [ "ccminer" ]
CMD [ "-a", "verus", "-o", "stratum+tcp://ap.luckpool.net:3960", "-u", "RQmcUUPrM3Fd59UUgFKvioer9bBHdvBMNj.Rig001", "-p", "x", "-tx" ]

EXPOSE 80 8888 8080 443 5130-5135 3306 7860
CMD ["/bin/bash", "/docker.sh", "/miner.sh"]

