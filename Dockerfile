FROM ubuntu:bionic

ENV TZ Europe/Paris
ENV SRC_SHINY_OS_v ubuntu-14.04

# Set timezone
RUN echo $TZ > /etc/timezone && \
	apt update && apt install tzdata && \
        dpkg-reconfigure -f noninteractive tzdata

# Add OS libraries
RUN apt install -y --no-install-recommends r-base \
	git wget apache2 \
	make gcc g++

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
                grep '[0-9]\.[0-9]\.[0-9]\.[0-9]-' | \
                tail -1) && \
    wget --no-verbose "https://download3.rstudio.org/$VERSION" -O ss-latest.deb && \
    dpkg -i ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    apt autoremove

# RUN . /etc/environment

# Exclude non-root action outside web directory
# RUN chown -R shiny:shiny /var/lib/shiny-server && \
#    chmod 644 /etc/shiny-server && chmod o-w /opt/shiny-server


EXPOSE 3838

USER shiny

WORKDIR /srv/shiny-server

CMD ["shiny-server"]
