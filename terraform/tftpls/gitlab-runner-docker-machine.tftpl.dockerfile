FROM gitlab/gitlab-runner:latest

RUN curl -O "https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.11/docker-machine-Linux-x86_64"
RUN mv docker-machine-Linux-x86_64 /usr/local/bin/docker-machine
RUN chmod +x /usr/local/bin/docker-machine

# To avoid creating certificates by multiple parallel processes
## See: https://github.com/docker/machine/issues/3634#issuecomment-575082182
# As far as I tested, no need to set environment variables
### See: https://gitlab.com/gitlab-org/gitlab-runner/issues/3676
### See: https://github.com/docker/machine/issues/3845#issuecomment-280389178
RUN docker-machine create --driver none --url localhost dummy-machine
RUN docker-machine rm -y dummy-machine