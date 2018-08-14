# Generated by Neurodocker version 0.4.1-9-g1f6df59
# Timestamp: 2018-08-14 18:18:52 UTC
# 
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
# 
#     https://github.com/kaczmarj/neurodocker

FROM neurodebian:stretch

ARG DEBIAN_FRONTEND="noninteractive"

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN export ND_ENTRYPOINT="/neurodocker/startup.sh" \
    && apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="en_US.UTF-8" \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> "$ND_ENTRYPOINT" \
    &&   echo 'set -e' >> "$ND_ENTRYPOINT" \
    &&   echo 'if [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' >> "$ND_ENTRYPOINT"; \
    fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker

ENTRYPOINT ["/neurodocker/startup.sh"]

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV FSLDIR="/opt/fsl-5.0.11" \
    PATH="/opt/fsl-5.0.11/bin:$PATH"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc \
           dc \
           file \
           libfontconfig1 \
           libfreetype6 \
           libgl1-mesa-dev \
           libglu1-mesa-dev \
           libgomp1 \
           libice6 \
           libmng1 \
           libxcursor1 \
           libxft2 \
           libxinerama1 \
           libxrandr2 \
           libxrender1 \
           libxt6 \
           wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading FSL ..." \
    && mkdir -p /opt/fsl-5.0.11 \
    && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-5.0.11-centos6_64.tar.gz \
    | tar -xz -C /opt/fsl-5.0.11 --strip-components 1 \
    && sed -i '$iecho Some packages in this Docker container are non-free' $ND_ENTRYPOINT \
    && sed -i '$iecho If you are considering commercial use of this container, please consult the relevant license:' $ND_ENTRYPOINT \
    && sed -i '$iecho https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence' $ND_ENTRYPOINT \
    && sed -i '$isource $FSLDIR/etc/fslconf/fsl.sh' $ND_ENTRYPOINT \
    && echo "Installing FSL conda environment ..." \
    && bash /opt/fsl-5.0.11/etc/fslconf/fslpython_install.sh -f /opt/fsl-5.0.11

ENV C3DPATH="/opt/convert3d-1.0.0" \
    PATH="/opt/convert3d-1.0.0/bin:$PATH"
RUN echo "Downloading Convert3D ..." \
    && mkdir -p /opt/convert3d-1.0.0 \
    && curl -fsSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download \
    | tar -xz -C /opt/convert3d-1.0.0 --strip-components 1

ENV PATH="/opt/afni-latest:$PATH" \
    AFNI_PLUGINPATH="/opt/afni-latest"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           ed \
           gsl-bin \
           libglib2.0-0 \
           libglu1-mesa-dev \
           libglw1-mesa \
           libgomp1 \
           libjpeg62 \
           libnlopt-dev \
           libxm4 \
           netpbm \
           r-base \
           r-base-dev \
           tcsh \
           xfonts-base \
           xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && curl -sSL --retry 5 -o /tmp/toinstall.deb http://mirrors.kernel.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb \
    && dpkg -i /tmp/toinstall.deb \
    && rm /tmp/toinstall.deb \
    && curl -sSL --retry 5 -o /tmp/toinstall.deb http://mirrors.kernel.org/debian/pool/main/libp/libpng/libpng12-0_1.2.49-1%2Bdeb7u2_amd64.deb \
    && dpkg -i /tmp/toinstall.deb \
    && rm /tmp/toinstall.deb \
    && apt-get install -f \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && gsl2_path="$(find / -name 'libgsl.so.19' || printf '')" \
    && if [ -n "$gsl2_path" ]; then \
         ln -sfv "$gsl2_path" "$(dirname $gsl2_path)/libgsl.so.0"; \
    fi \
    && ldconfig \
    && echo "Downloading AFNI ..." \
    && mkdir -p /opt/afni-latest \
    && curl -fsSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz \
    | tar -xz -C /opt/afni-latest --strip-components 1 \
    && PATH=$PATH:/opt/afni-latest rPkgsInstall -pkgs ALL

ENV ANTSPATH="/opt/ants-2.2.0" \
    PATH="/opt/ants-2.2.0:$PATH"
RUN echo "Downloading ANTs ..." \
    && mkdir -p /opt/ants-2.2.0 \
    && curl -fsSL --retry 5 https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz \
    | tar -xz -C /opt/ants-2.2.0 --strip-components 1

ENV C3DPATH="/opt/convert3d-nightly" \
    PATH="/opt/convert3d-nightly/bin:$PATH"
RUN echo "Downloading Convert3D ..." \
    && mkdir -p /opt/convert3d-nightly \
    && curl -fsSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/Nightly/c3d-nightly-Linux-x86_64.tar.gz/download \
    | tar -xz -C /opt/convert3d-nightly --strip-components 1

ENV XCPEDIR="/xcpEngine-master" \
    FSLDIR="/opt/fsl-5.0.11" \
    AFNI_PATH="/opt/afni-latest" \
    C3D_PATH="/opt/convert3d-nightly/bin"

RUN sed -i '$iexport XCPEDIR=/xcpEngine-master' $ND_ENTRYPOINT

RUN sed -i '$iexport FSLDIR=/opt/fsl-5.0.11' $ND_ENTRYPOINT

RUN sed -i '$iexport AFNI_PATH=/opt/afni-latest' $ND_ENTRYPOINT

RUN sed -i '$iexport C3D_PATH=/opt/convert3d-nightly/bin' $ND_ENTRYPOINT

RUN sed -i '$iexport ANTSPATH=/opt/ants-2.2.0' $ND_ENTRYPOINT

RUN sed -i '$iexport PATH=$PATH:$XCPEDIR' $ND_ENTRYPOINT

RUN bash -c 'cd / && wget https://github.com/PennBBL/xcpEngine/archive/master.zip && unzip master.zip'

RUN bash -c 'XCPEDIR=/xcpEngine-master FSLDIR=/opt/fsl-5.0.11 AFNI_PATH=/opt/afni-latest C3D_PATH=/opt/convert3d-nightly/bin ANTSPATH=/opt/ants-2.2.0 /xcpEngine-master/xcpReset'

RUN bash -c 'export PATH=/opt/afni-latest:$PATH && rPkgsInstall -pkgs ALL && rPkgsInstall -pkgs optparse,pracma,RNifti,svglite,signal,reshape2,ggplot2,lme4'

RUN bash -c ' echo =========================='

RUN bash -c 'cat $ND_ENTRYPOINT'

RUN bash -c ' echo =========================='

ENTRYPOINT ["/neurodocker/startup.sh", "/xcpEngine-master/xcpEngine", "\"$@\""]

RUN echo '{ \
    \n  "pkg_manager": "apt", \
    \n  "instructions": [ \
    \n    [ \
    \n      "base", \
    \n      "neurodebian:stretch" \
    \n    ], \
    \n    [ \
    \n      "install", \
    \n      [ \
    \n        "wget" \
    \n      ] \
    \n    ], \
    \n    [ \
    \n      "fsl", \
    \n      { \
    \n        "version": "5.0.11" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "convert3d", \
    \n      { \
    \n        "version": "1.0.0", \
    \n        "method": "binaries" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "afni", \
    \n      { \
    \n        "version": "latest", \
    \n        "install_r": "true", \
    \n        "install_r_pkgs": "true" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "ants", \
    \n      { \
    \n        "version": "2.2.0" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "convert3d", \
    \n      { \
    \n        "version": "nightly" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "env", \
    \n      { \
    \n        "XCPEDIR": "/xcpEngine-master", \
    \n        "FSLDIR": "/opt/fsl-5.0.11", \
    \n        "AFNI_PATH": "/opt/afni-latest", \
    \n        "C3D_PATH": "/opt/convert3d-nightly/bin" \
    \n      } \
    \n    ], \
    \n    [ \
    \n      "add_to_entrypoint", \
    \n      "export XCPEDIR=/xcpEngine-master" \
    \n    ], \
    \n    [ \
    \n      "add_to_entrypoint", \
    \n      "export FSLDIR=/opt/fsl-5.0.11" \
    \n    ], \
    \n    [ \
    \n      "add_to_entrypoint", \
    \n      "export AFNI_PATH=/opt/afni-latest" \
    \n    ], \
    \n    [ \
    \n      "add_to_entrypoint", \
    \n      "export C3D_PATH=/opt/convert3d-nightly/bin" \
    \n    ], \
    \n    [ \
    \n      "add_to_entrypoint", \
    \n      "export ANTSPATH=/opt/ants-2.2.0" \
    \n    ], \
    \n    [ \
    \n      "add_to_entrypoint", \
    \n      "export PATH=$PATH:$XCPEDIR" \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      "cd / && wget https://github.com/PennBBL/xcpEngine/archive/master.zip && unzip master.zip" \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      "XCPEDIR=/xcpEngine-master FSLDIR=/opt/fsl-5.0.11 AFNI_PATH=/opt/afni-latest C3D_PATH=/opt/convert3d-nightly/bin ANTSPATH=/opt/ants-2.2.0 /xcpEngine-master/xcpReset" \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      "export PATH=/opt/afni-latest:$PATH && rPkgsInstall -pkgs ALL && rPkgsInstall -pkgs optparse,pracma,RNifti,svglite,signal,reshape2,ggplot2,lme4" \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      " echo ==========================" \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      "cat $ND_ENTRYPOINT" \
    \n    ], \
    \n    [ \
    \n      "run_bash", \
    \n      " echo ==========================" \
    \n    ], \
    \n    [ \
    \n      "entrypoint", \
    \n      "/neurodocker/startup.sh /xcpEngine-master/xcpEngine \"$@\"" \
    \n    ] \
    \n  ] \
    \n}' > /neurodocker/neurodocker_specs.json
