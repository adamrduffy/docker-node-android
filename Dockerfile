FROM jenkins/jenkins:lts
USER root

# install node
ENV NODE_VERSION=12.6.0
RUN apt install -y curl

ENV NVM_DIR=/usr/local/nvm
RUN mkdir "$NVM_DIR"
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/usr/local/nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

# create the .npm directory and grant everyone access to it
RUN mkdir /.npm
RUN chmod 777 /.npm
RUN touch /.npmrc
RUN chmod 777 /.npmrc

# install ionic
RUN npm install -g @ionic/cli

ENV SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip" \
    ANDROID_HOME="/usr/local/android-sdk" \
    ANDROID_VERSION=29 \
    ANDROID_BUILD_TOOLS_VERSION=28.0.3
# Download Android SDK
RUN mkdir "$ANDROID_HOME" .android \
    && cd "$ANDROID_HOME" \
    && curl -o sdk.zip $SDK_URL \
    && unzip sdk.zip \
    && rm sdk.zip \
    && mkdir "$ANDROID_HOME/licenses" || true \
    && echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license" \
    && yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses
# Install Android Build Tool and Libraries
RUN $ANDROID_HOME/tools/bin/sdkmanager --update
RUN $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_VERSION}" \
    "platform-tools"
ENV PATH="${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/:${PATH}"
RUN chmod 777 $ANDROID_HOME
RUN chmod 777 $ANDROID_HOME/build-tools

# install gradle
ENV GRADLE_URL="https://services.gradle.org/distributions/gradle-4.10.3-bin.zip"
ENV GRADLE_HOME="/usr/local/gradle"
RUN mkdir "$GRADLE_HOME" \
    && cd "$GRADLE_HOME" \
	&& curl --location --show-error -o gradle.zip $GRADLE_URL \
	&& unzip gradle.zip \
	&& rm gradle.zip
ENV PATH="${GRADLE_HOME}/gradle-4.10.3/bin/:${PATH}"	
RUN gradle --version

# Jenkins configuration-as-code environment variable
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/casc.yaml

# docker installation - no longer required
# RUN apt-get update && \
#     apt-get -y install apt-transport-https \
#       ca-certificates \
#      curl \
#      gnupg2 \
#      software-properties-common && \
#    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
#    add-apt-repository \
#      "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
#      $(lsb_release -cs) \
#      stable" && \
#   apt-get update && \
#   apt-get -y install docker-ce

# install jenkins plugins
COPY ./jenkins-plugins /usr/share/jenkins/plugins
RUN while read i ; \
                do /usr/local/bin/install-plugins.sh $i ; \
        done < /usr/share/jenkins/plugins

#Update the username and password
ENV JENKINS_USER admin
ENV JENKINS_PASS ThisIs@StrongP@ssword

#id_rsa.pub file will be saved at /root/.ssh/
RUN ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''

# allows to skip Jenkins setup wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# Jenkins configuration-as-code file
COPY casc.yaml ${CASC_JENKINS_CONFIG}

# add user
RUN useradd -ms /bin/bash "Adam.Duffy" -l -u 1000500000

VOLUME /var/jenkins_home