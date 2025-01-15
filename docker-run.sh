docker compose down

if [ "$1" == "clean" ]; then
    [ -d "./data" ] && rm -rf ./data/app ./data/config ./data/data/custom_nodes ./data/data/user ./data/data/temp
    [ -d "./data_beta" ] && rm -rf ./data_beta/app ./data_beta/config ./data_beta/data/custom_nodes ./data_beta/data/user ./data_beta/data/temp
fi

cd; cd -; docker compose up -d && docker compose logs -f