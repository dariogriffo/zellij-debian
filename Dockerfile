ARG DEBIAN_DIST=bookworm
FROM debian:bookworm

ARG DEBIAN_DIST
ARG zellij_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/share/doc/zellij
RUN mkdir -p /output/DEBIAN

COPY zellij /output/usr/bin/zellij
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/zellij/
COPY output/changelog.Debian /output/usr/share/doc/zellij/
COPY output/README.md /output/usr/share/doc/zellij/

RUN chmod 755 /output/usr/bin/zellij

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/zellij/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/zellij/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/zellij_VERSION/$zellij_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

RUN dpkg-deb --build /output /zellij_${FULL_VERSION}.deb
