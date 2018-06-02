#!/bin/bash -e

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

while getopts "a:v:q:u:d:" opt; do
    case "$opt" in
    a)  ARCH=$OPTARG
        ;;
    v)  VERSION=$OPTARG
        ;;
    q)  QEMU_ARCH=$OPTARG
        ;;
    u)  QEMU_VER=$OPTARG
        ;;
    d)  DOCKER_REPO=$OPTARG
        ;;
    esac
done

#Workaround to push manifests
if [ "$ARCH" = "all" ]; then
	exit 0
fi

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

ROOTFS=rootfs

debootstrap --foreign --variant=minbase --components=main --arch=$ARCH --include=inetutils-ping,iproute2  ${VERSION} $ROOTFS http://httpredir.debian.org/debian


# install qemu-user-static
if [ -n "${QEMU_ARCH}" ]; then
    if [ ! -f x86_64_qemu-${QEMU_ARCH}-static.tar.gz ]; then
        wget -N https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VER}/x86_64_qemu-${QEMU_ARCH}-static.tar.gz
    fi
    tar -xvf x86_64_qemu-${QEMU_ARCH}-static.tar.gz -C $ROOTFS/usr/bin/
fi

DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
 LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS /debootstrap/debootstrap --second-stage
 
 DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
 LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS dpkg --configure -a
 
echo "deb http://httpredir.debian.org/debian ${VERSION} main contrib non-free" > $ROOTFS/etc/apt/sources.list
 
# create tarball of rootfs
if [ ! -f rootfs.tar.xz ]; then
    tar --numeric-owner -C $ROOTFS -c . | xz > rootfs.tar.xz
fi

# create Dockerfile
cat > Dockerfile <<EOF
FROM scratch
ADD rootfs.tar.xz /
ENV ARCH=${ARCH} DOCKER_REPO=${DOCKER_REPO}
EOF

# add qemu-user-static binary
if [ -n "${QEMU_ARCH}" ]; then
    cat >> Dockerfile <<EOF
# Add qemu-user-static binary for amd64 builders
ADD x86_64_qemu-${QEMU_ARCH}-static.tar.gz /usr/bin
EOF
fi

# build
docker build -t "${DOCKER_REPO}:${ARCH}-${VERSION}" .

