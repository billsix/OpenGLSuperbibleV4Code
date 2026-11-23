FROM registry.fedoraproject.org/fedora:45

# System-package installation lives in per-group scripts (entrypoint/0N-install-*.sh), host-runnable with
# no container runtime. The dnf cache mount, the tsflags sed and keepcache are build plumbing and stay here.
COPY entrypoint/01-install-base.sh entrypoint/02-install-graphics.sh /usr/local/bin/

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    --mount=type=cache,target=/var/lib/dnf \
    sed -i -e "s@tsflags=nodocs@#tsflags=nodocs@g" /etc/dnf/dnf.conf && \
    echo "keepcache=True" >> /etc/dnf/dnf.conf && \
    /usr/local/bin/01-install-base.sh && \
    /usr/local/bin/02-install-graphics.sh
