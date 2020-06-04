CONFIG_PATH=/usr/odk/config/local.json
if [ ! -e "$CONFIG_PATH" ]
then
  echo "generating local service configuration.."
  /bin/bash -c "envsubst '\$DOMAIN:\$DOMAIN_PROTOCOL' < /usr/share/odk/config.json.template > $CONFIG_PATH"
fi

echo "running migrations.."
node -e 'const { withDatabase, migrate } = require("./lib/model/database"); withDatabase(require("config").get("default.database"))(migrate);'

echo "starting cron.."
cron -f &

MEMTOT=$(vmstat -s | grep 'total memory' | awk '{ print $1 }')
if [ "$MEMTOT" -gt "1100000" ]
then
  WORKER_COUNT=4
else
  WORKER_COUNT=1
fi
echo "using $WORKER_COUNT worker(s) based on available memory ($MEMTOT).."

echo "starting server."
mkdir -p /var/log/odk
node node_modules/naught/lib/main.js start --remove-old-ipc true --worker-count $WORKER_COUNT --daemon-mode false --log /var/log/odk/naught.log --stdout /var/log/odk/stdout.log --stderr /var/log/odk/stderr.log lib/bin/run-server.js

