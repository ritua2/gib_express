FROM node:6

ADD . /app
WORKDIR /app
RUN npm install
RUN apt-get update && \
    apt-get install -y vim
RUN groupadd --gid 818565 G-818565 && \
    useradd --create-home --shell /bin/bash term && \
    echo 'term:term' | chpasswd
RUN chmod -R 777 /root && \
    chown -R term:G-818565 /home/term && \
    chmod -R 777 /app/public

RUN cd ~
RUN apt-get install -y zsh
RUN apt-get clean
RUN apt-get autoclean
RUN apt-get autoremove -y
RUN rm -rf /var/lib/cache/*
RUN rm -rf /var/lib/log/*
USER term
RUN chown -R term /home/term && echo "all done"
RUN git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
#RUN cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
RUN cp /app/.zshrc ~/.zshrc
RUN echo "term" | chsh -s /bin/zsh
USER root

EXPOSE 3000

ENTRYPOINT ["node"]
CMD ["app.js", "-p", "3000"]
