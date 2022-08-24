FROM ubuntu
ARG SERVER_IP
RUN apt-get update \ 
    && apt-get install gcc automake autoconf libtss2-dev libssl-dev make libsystemd-dev libtss2-tcti-tabrmd0 libtss2-dev pkg-config build-essential wget tar -y \
    && cd ~ \
    && wget https://download.strongswan.org/strongswan-5.9.7.tar.gz \
    && tar xzvf strongswan-5.9.7.tar.gz \
    && cd strongswan-5.9.7 \
    && ./configure --prefix=/usr --sysconfdir=/etc --with-systemdsystemunitdir=/lib/systemd/system --enable-eap-identity --enable-eap-mschapv2 --enable-tpm --enable-tss-tss2 --enable-systemd --enable-swanctl --disable-charon --disable-stroke --disable-scepclient --disable-gmp --enable-openssl --disable-dependency-tracking \
    && make && make install && cd ~ \
    && mkdir -p pki && chmod 700 ~/pki && cd pki \
    && pki --gen --type rsa --size 4096 --outform pem > vpnca.key.pem \
    && pki --self --flag serverAuth --in vpnca.key.pem --type rsa --digest sha256 --dn "C=KR, O=Organization, CN=VPN KR CA" --ca > vpnca.crt.der \
    && pki --gen --type rsa --size 4096 --outform pem > ${SERVER_IP}.key.pem \
    && pki --pub --in ${SERVER_IP}.key.pem --type rsa > ${SERVER_IP}.csr \
    && pki --issue --cacert vpnca.crt.der --cakey vpnca.key.pem --digest sha256 --dn "C=KR, O=Organization, CN=${SERVER_IP}" --san "${SERVER_IP}" --flag serverAuth --flag ikeIntermediate --outform pem < ${SERVER_IP}.csr > ${SERVER_IP}.crt.pem \
    && cp vpnca.crt.der /etc/swanctl/x509ca/vpnca.crt.der \
    && cp ${SERVER_IP}.crt.pem /etc/swanctl/x509/server.crt.pem \
    && cp ${SERVER_IP}.key.pem /etc/swanctl/private/server.key.pem \
    && chown root:root /etc/swanctl/private/server.key.pem \
    && chmod 600 /etc/swanctl/private/server.key.pem

EXPOSE 500/udp 4500/udp

