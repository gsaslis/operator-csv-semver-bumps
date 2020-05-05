FROM centos:8

WORKDIR /workdir

# install yq
RUN curl --location --output yq https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 \
  && chmod +x yq \
  && mv yq /usr/bin/yq

COPY bump.sh /workdir/bump.sh
RUN chmod +x /workdir/bump.sh

ENTRYPOINT ["/workdir/bump.sh"]