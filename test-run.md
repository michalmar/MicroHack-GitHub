## remove running cintainers if exists
docker container rm -f cosmos-emulator petpal-ui 2>/dev/null || true

# pull docker image
docker pull ghcr.io/michalmar/petpal-ui:latest



# Run Cosmos DB Emulator in Docker (Linux)
docker run \
   --name cosmos-emulator \
   --detach \
   --publish 8081:8081 \
   --publish 10250-10255:10250-10255 \
   mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:latest



docker container rm -f petpal-ui 2>/dev/null || true
# run frontend
docker run -d \
   -p 3000:80 \
   -e VITE_API_PETS_URL=https://organic-journey-v6wj64pv64526wp4-8010.app.github.dev \
   -e VITE_API_ACTIVITIES_URL=https://organic-journey-v6wj64pv64526wp4-8020.app.github.dev \
   -e VITE_API_ACCESSORIES_URL=https://organic-journey-v6wj64pv64526wp4-8030.app.github.dev \
   -e VITE_API_GITHUB_TOKEN=$GITHUB_TOKEN \
   --name petpal-ui \
   ghcr.io/michalmar/petpal-ui:latest
