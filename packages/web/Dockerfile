FROM dart:3.14.1 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
COPY packages/shared/pubspec.yaml packages/shared/pubspec.yaml
COPY packages/server/pubspec.yaml packages/server/pubspec.yaml
COPY packages/web/pubspec.yaml packages/web/pubspec.yaml
RUN dart pub get --enforce-lockfile

RUN dart pub global activate jaspr_cli 0.24.0-beta.2
ENV PATH="${PATH}:/root/.pub-cache/bin"

COPY packages/shared packages/shared
COPY packages/web packages/web

ARG API_BASE_URL=http://localhost:8080
WORKDIR /app/packages/web
RUN jaspr build --dart-define=API_BASE_URL=${API_BASE_URL} \
  && rm -rf build/jaspr/.dart_tool build/jaspr/.build.manifest

FROM nginx:alpine

COPY packages/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/packages/web/build/jaspr/ /usr/share/nginx/html/

EXPOSE 8081
