# memo

USER coder
RUN mkdir /home/coder/extensions && \
    cd /home/coder/extensions && \
    wget https://github.com/redhat-developer/vscode-java/releases/download/v1.21.0/java-1.21.0.vsix

ENV VSCODE_USER /home/coder/.local/share/code-server/User
ENV VSCODE_EXTENSIONS /home/coder/.local/share/code-server/extensions
RUN code-server --install-extension MS-CEINTL.vscode-language-pack-ja
RUN code-server --install-extension /home/coder/extensions/java-1.21.0.vsix

RUN code-server --install-extension vscjava.vscode-java-debug
RUN code-server --install-extension vscjava.vscode-java-test
                                   
RUN code-server --install-extension vscjava.vscode-maven
RUN code-server --install-extension vscjava.vscode-java-dependency
RUN code-server --install-extension redhat.vscode-yaml
RUN code-server --install-extension adashen.vscode-tomcat
RUN code-server --install-extension dgileadi.java-decompiler

RUN code-server --install-extension vscode-icons-team.vscode-icons
RUN code-server --install-extension esbenp.prettier-vscode
RUN code-server --install-extension redhat.vscode-community-server-connector
RUN code-server --install-extension redhat.vscode-rsp-ui
RUN code-server --install-extension oderwat.indent-rainbow
RUN code-server --install-extension ecmel.vscode-html-css
RUN code-server --install-extension formulahendry.auto-rename-tag
RUN code-server --install-extension donjayamanne.githistory
RUN code-server --install-extension mhutchie.git-graph

RUN rm -rf /home/coder/extensions
