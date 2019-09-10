#!
mv /usr/bin/envsubst /tmp/ \
apt-get autoremove -y \
&& rm -rf var/cache/apt/* \
&& :

