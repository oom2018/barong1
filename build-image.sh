alias dc="docker-compose"

echo "Make sure run in VM and app user!"
sleep 1

echo "Render DBEX config:"
cd /home/app/github.com/oom2018/dbex  || exit
rake render:config

echo "Build barong:"
cd /home/app/github.com/oom2018/barong || exit

ehco "Make sure you have [~/data/desktop/3.8.3] for cypress!"
echo "And run: cd ~/data/ && http-server -p 80"
sleep 1

if export CYPRESS_DOWNLOAD_MIRROR="http://192.168.75.1/" && yarn install && yarn build; then
	if docker build -t my_barong:1.0.0 --build-arg BUILD_DOMAIN="proxy.xlife.top" .; then
		echo "build error, exit!"
		exit 1
	fi

	cd - || exit

	dc rm -fsv barong
	dc up -d barong
fi
