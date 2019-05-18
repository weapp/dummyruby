export BRANCH="$(echo "${TRAVIS_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}" | sed -e 's/\//-/g')"
export DATE_FORMAT="%Y%m%dT%H%M%SZ"
export TS=$(git show -s --format=%ct)
export DATE=$(date -u +${DATE_FORMAT} -d@${TS} || date -u -r ${TS} +${DATE_FORMAT})
export REV=$(git rev-parse --short HEAD)
export TAG_NAME="${BRANCH}-${DATE}-${REV}"

docker build . -t $(APP_NAME):latest --build-arg TAG_NAME=$(TAG_NAME)
# docker tag $(APP_NAME):latest gcr.io/$(PROJECT)/$(APP_NAME):latest
docker tag $(APP_NAME):latest weapp/$(APP_NAME):latest
