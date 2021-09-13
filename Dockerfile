FROM ubuntu:focal

ENV TZ Europe/Paris
ENV SRC_SHINY_OS_v ubuntu-14.04
ENV R_FINGERPRINT E298A3A825C0D65DFD57CBB651716619E084DAB9

# Set timezone
RUN echo $TZ > /etc/timezone && \
	apt update -qq && \
	apt install -y --no-install-recommends \
	  software-properties-common \
          dirmngr \
	  wget \
          tzdata && \
        dpkg-reconfigure -f noninteractive tzdata

# Add repositories
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
	tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

RUN [ "$(gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc | \
	head -2 | tail -1 | sed 's/^\s*//')" = "${R_FINGERPRINT}" ] || exit 1

RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" && \
	add-apt-repository ppa:c2d4u.team/c2d4u4.0+

# Add OS libraries
RUN apt install -y --no-install-recommends \
	r-base \
	apache2 \
	make \
	gcc \
	g++ \
	zlib1g-dev

# Add R packages
RUN R -e "install.packages(c('shiny', 'rmarkdown', 'ggplot2'), repos='https://cran.rstudio.com/')"

# Add Shiny Server CE
# Uses last x.x.x.x-version
VOLUME /srv/shiny-server/

RUN wget --no-verbose https://download3.rstudio.org -O "version.txt" && \
    VERSION=$(cat version.txt | \
                sed -z 's/<Key>/\n/g' | \
                sed 's/deb.*$/deb/g' | \
                grep $SRC_SHINY_OS_v | \
                grep 'deb$' | \
                tail -1) && \
    wget --no-verbose "https://download3.rstudio.org/$VERSION" -O ss-latest.deb && \
    dpkg -i ss-latest.deb && \
    rm -f version.txt ss-latest.deb

RUN apt remove -y \
	software-properties-common \
        dirmngr \
        wget \
	make \
        gcc \
        g++ && \
    apt autoremove -y

# RUN . /etc/environment

# Exclude non-root action outside web directory
# RUN chown -R shiny:shiny /var/lib/shiny-server && \
#    chmod 644 /etc/shiny-server && chmod o-w /opt/shiny-server


EXPOSE 3838

USER shiny

WORKDIR /srv/shiny-server

CMD ["shiny-server"]
